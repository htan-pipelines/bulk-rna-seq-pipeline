somalier_stats <- function(somalier_file, sample_id, participant_id) {
  #read in somalier file
  somalier.pairs <- read.delim(somalier_file, header=TRUE, stringsAsFactors=FALSE)


  #match participant ids to id names
  somalier.pairs$sample_a_id <- participant_id[match(somalier.pairs$X.sample_a,sample_id)]
  somalier.pairs$sample_b_id <- participant_id[match(somalier.pairs$sample_b,sample_id)]



  #initialize matrix of proper size
  par_out<-matrix(ncol= 12, nrow = length(sample_id))


  #first computes all samples for relatedness to samples not labeled as same participant
  #then works on the samples that are supposed to be related (checks to see if any pairs have same participant id and then breaks inner for loop)
  for (i in 1:nrow(par_out)) {
    ix <- somalier.pairs$sample_a_id == participant_id[i] & somalier.pairs$sample_b_id != participant_id[i] | somalier.pairs$sample_a_id != participant_id[i] & somalier.pairs$sample_b_id == participant_id[i]
    su <- summary(somalier.pairs$relatedness[ix])
    par_out[i,5:8]<-su[c(4,3,6,1)]
    temp<-somalier.pairs[ix,]
    for (m in 1:nrow(somalier.pairs[ix,])) {
      if (temp$relatedness[m]>0.8){
        par_out[i,12]<-unique(c(temp$X.sample_a[ix & temp$relatedness > .8],temp$sample_b[ix & temp$relatedness > .8]))
        break
      }
    }
    for (j in 1:nrow(somalier.pairs)) {
      if (somalier.pairs$sample_a_id[j] == participant_id[i] & somalier.pairs$sample_b_id[j] == participant_id[i]) {
        ix <- somalier.pairs$sample_a_id == participant_id[i] & somalier.pairs$sample_b_id == participant_id[i]
        su <- summary(somalier.pairs$relatedness[ix])
        par_out[i,1:4]<-su[c(4,3,6,1)]
        par_out[i,9:10]<-c(length(unique(c(somalier.pairs$sample_b[ix], somalier.pairs$X.sample_a[ix]))), paste(unique(c(somalier.pairs$sample_b[ix & somalier.pairs$sample_b != sample_id[i]], somalier.pairs$X.sample_a[ix & somalier.pairs$X.sample_a != sample_id[i]])), collapse =", "))
        temp<-somalier.pairs[ix,]
        for (m in 1:nrow(somalier.pairs[ix,])) {
          if (temp$relatedness[m]<0.8){
            par_out[i,12]<-paste(unique(c(temp$X.sample_a[ix & temp$relatedness < .8],temp$sample_b[ix & temp$relatedness < .8])), collapse = ", ")
            break
          }
        }
        break
      }
    }
  }

  rownames(par_out)<-sample_id
  colnames(par_out)<-c("somalier_relatedness_mean", "somalier_relatedness_median", "somalier_relatedness_max", "somalier_relatedness_min", "somalier_other_relatedness_mean", "somalier_other_relatedness_median", "somalier_other_relatedness_max", "somalier_other_relatedness_min", "somalier_relatedness_num_samples", "somalier_relatedness_matching_participant_samples", "somalier_related_flag", "somalier_unrelated_flag")

  write.table(par_out, "somalier.final.tsv", quote = F, sep="\t")

}


args <- commandArgs(trailingOnly = TRUE)
#read in somalier file
somalier_file <- args[1]
sample_id <-args[2]
sample_id <- strsplit(unlist(sample_id), split=',')
sample_id <- unlist(sample_id, use.names = FALSE)
participant_id <- args[3]
participant_id <- strsplit(participant_id, split=',')
participant_id <- unlist(participant_id, use.names = FALSE)


somalier_stats(somalier_file = somalier_file, sample_id = sample_id, participant_id = participant_id)