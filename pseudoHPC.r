### Pseudo-high performance computing (PHPC)
### Adam B. Smith | Missouri Botanical Garden | adam.smith@mobot.org | 2020-03
###
### This script demonstrates a method for coupling jobs across multiple computers which share a server but otherwise don't "talk" with one another. The procedure is designed for testing a large number of scenarios where the parameters defining the scenarios change in predictable ways (e.g., low/medium/high clustering, low/medium/high spatial heterogeneity, etc.). The procedure is as follows:
###
### 1 Each computer generates a data frame with the different parameters defining different scenarios. The data frames are the same between computers. For example, if you wished to vary clustering across the values 1, 2, and 3 and spatial heterogeneity across values "low", "medium", and "high", then the data frame would look like:
###		progress <- expand.grid(clustering=1:3, hetero = c('low', 'medium', 'high'))
###
### 2 When the first computer is started with a job, it creates the data frame. It then generates a set of strings created by pasting the values in each row of the data frame. For example:
###
###		jobs <- paste(progress$clustering, progress$hetero, sep=' ')
###
### 	Then, the computer writes a very small file (e.g., a CSV file with nothing in it) to a pre-determined folder on the server named "starts" (or something like that). The name of the file is the name of the first job (e.g., "clustering = 1 hetero = low"). It then starts on this job.
###
### 3 When subsequent computers are started they check in the "starts" folder where the "job" files are stored. If a job file exists there the computers assume that the job is being done, so look to see if there are any jobs that need done but don't have job files. If so, they choose one, write the job file to "starts", and start working on the job.
###
### 4 When a computer is done with the job it write a second job file to a folder named "stops". It then looks in the "starts" folder to see what job hasn't been started yet.
###
### 5 Repeat!
###
### NB The purpose of the "stops" folder is to help you know if all of the jobs have been completed. For example, a computer might start a job but not be able to finish it (power outage, etc.). If all of the jobs are complete then the files in "starts" should be the same as the files in "stops".

###############
### EXAMPLE ###
###############

	### create progress data frame
	
	# doing it the hard way... could probably do this more easily with "grid.expand"
	
	progress <- data.frame()
	rot <- c(22.5, 90, 157.5)
	rho <- c(-0.75, 0, 0.75)
	sigmaValues <- c(0.1, 0.3, 0.5)

	for (rot in rot) {
		for (thisRho in rho) {
			for (countSigma1 in seq_along(sigmaValues)) {
				for (countSigma2 in countSigma1:length(sigmaValues)) {
					
					line <- data.frame(
						rot=rot,
						rho=thisRho,
						sigma1=sigmaValues[countSigma1],
						sigma2=sigmaValues[countSigma2]
					)
					line$job <- paste(names(line), line, collapse=' ', sep='=')
					progress <- rbind(progress, line)
					
				}
			}
		}
	}

	dir.create('./starts', showWarnings=FALSE)
	dir.create('./stops', showWarnings=FALSE)

	# get list of jobs that have been started
	started <- list.files('./starts')

	### for each SCENARIO
	while (length(started) < nrow(progress)) {
	
		# get row number of next scenario that needs done
		if (length(started) == 0) {
			doing <- 1
		} else {
			doing <- progress$job[-match(started, progress$job)][1]
			doing <- which(progress$job==doing)
		}
		
		# name of job to do
		job <- progress$job[doing]
		
		write.csv(NA, paste0('./starts/', job), row.names=FALSE)

		# define parameters for this simulation (just an example!)
		rot <- progress$rot[doing]
		thisRho <- progress$rho[doing]
		thisSigma1 <- progress$sigma1[doing]
		thisSigma2 <- progress$sigma2[doing]

		# report progress
		print(paste0('rot = ', rot, ' | rho = ', thisRho, ' | sigma1 = ', thisSigma1, ' | sigma2 = ', thisSigma2))
		flush.console()
	
		# some function
		out <- someFunctionWorthDoing(
			rot=rot,
			rho=thisRho
			sigma1=thisSigma1
			sigma2=thisSigma2
		)

		# save results...
		# note that if the function write a file with results (it probably will)
		# you will want to append the name of the job to the file so it will be
		# distinct from other files created by other computers/other runs on this
		# computer!
		fileName <- paste0('./results/file name ', job, '.RData')
		save(out, file=fileName)
			
		# save job file in "completed" folder
		write.csv(NA, paste0('./stops/', job), row.names=FALSE)
		
		# get list of jobs that have been started
		started <- list.files(paste0('./starts'))

	} # next scenario
