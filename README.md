# Pseudo-high performance computing (pseudoHPC)  
Adam B. Smith | Missouri Botanical Garden | adam.smith@mobot.org

This script demonstrates a method for coupling jobs across multiple computers which share a server but otherwise don't "talk" with one another. The procedure is best used for testing a large number of scenarios where the parameters defining the scenarios change in predictable ways (e.g., low/medium/high clustering, low/medium/high spatial heterogeneity, etc.). The procedure is as follows:

1. Each computer generates a data frame with the different parameters defining different scenarios. The data frames are the same between computers. For example, if you wished to vary clustering across the values 1, 2, and 3 and spatial heterogeneity across values "low", "medium", and "high", then the data frame would look like:

`		progress <- expand.grid(clustering=1:3, hetero = c('low', 'medium', 'high'))

2. When the first computer is started with a job, it creates the data frame. It then generates a set of strings created by pasting the values in each row of the data frame. For example:

`		jobs <- c(  
			'clustering = 1 hetero = low', \cr
			'clustering = 1 hetero = medium', \cr 
			'clustering = 1 hetero = high', \cr
			'clustering = 2 hetero = low', \cr
			'clustering = 2 hetero = medium', \cr
			'clustering = 2 hetero = high', \cr
			'clustering = 3 hetero = low', \cr
			'clustering = 3 hetero = medium', \cr
			'clustering = 3 hetero = high' \cr
		)
`

Then, the computer writes a very small file (e.g., a CSV file with nothing in it) to a folder on the server named "`starts`" (or something like that). The name of the file is the name of the first job (e.g., "`clustering = 1 hetero = low`"). It then starts on this job.

3. When subsequent computers are started they check in the "`starts`" folder where the "job" files are stored. If a job file exists there the computers assume that the job is being done, so look to see if there are any jobs that need done but don't have job files. If so, they choose one, write the job file to "`starts`", and start working on the job.

4. When a computer is done with the job it write a second job file to a folder named "`stops`". It then looks in the "`starts`" folder to see what job hasn't been started yet.

5. Repeat!

NB The purpose of the "`stops`" folder is to help you know if all of the jobs have been completed. For example, a computer might start a job but not be able to finish it (power outage, etc.). If all of the jobs are complete then the files in "`starts`" should be the same as the files in "`stops`".
