library(arc)
#install.packages("ROCR")
library(ROCR)

message("Executing CBA")
#these matrices are currently for the binary bow vectorization

matrixNameXtrain <- "X_train_rules.csv"
matrixNameXtest <- "X_test_rules.csv"
matrixNameytrain <- "y_train_rules.csv"
matrixNameytest <- "y_test_rules.csv"

if (!(exists("trainFold_X")))
{
    warning("Reading data from disk")
    trainFold_X <- read.csv(matrixNameXtrain,row.names = 1)
    trainFold_Y <- read.csv(matrixNameytrain,row.names = 1)
    testFold_X <- read.csv(matrixNameXtest,row.names = 1)
    testFold_Y <- read.csv(matrixNameytest,row.names = 1, stringsAsFactors=T)        
}

if (!(exists("candidate_rule_limit")))
{
    warning("Using 50000 as candidate_rule_limit")
    candidate_rule_limit <-50000
}

if (!(exists("exp_name")))
{
    warning("Using default exp_name to save to disk")
    exp_name <-"cba"
}

if (!(exists("result_path")))
{
    warning("Using default result path to save to disk")
    result_path <-"./results/rule_lists/"
}

trainFold_X[] <- lapply(trainFold_X, as.logical)
testFold_X[] <- lapply(testFold_X, as.logical)
classAtt <- "Target"
Target<- as.factor(trainFold_Y[[classAtt]])
Target_oracle<- as.factor(testFold_Y[[classAtt]])
trainFold <-cbind(trainFold_X,Target)
trans <- as(trainFold, "transactions")
appearance <- arc::getAppearance(trainFold, classAtt)


rules <- apriori(trans, parameter =
                   list(confidence = 0.5, support= 0.01, minlen=1, maxlen=4, maxtime=5), appearance=appearance)

#this can be used to take only a subset of rules, now use all
#candidate_rule_limit<- 50000


message("Rule mining finished")
message(paste0("Trimming the rule list to ",candidate_rule_limit))
if (length(rules) > candidate_rule_limit)
{
  subs_rules<-rules[0:candidate_rule_limit]  
} else {
  subs_rules <- rules
}
#this takes about 1 minute
rmCBA <- cba_manual(trainFold,subs_rules, trans, cutp = list(), appearance$rhs, classAtt)
message("CBA finished")
prediction <- predict(rmCBA, testFold_X)
message("Prediction finished")

#přidáno
rules_length <- length(rmCBA@rules)
avgRuleLengthCBA <- sum(rmCBA@rules@lhs@data)/length(rmCBA@rules)


write(rmCBA@rules, file = paste0(result_path,exp_name,"-rules.csv"))
write(prediction, file =  paste0(result_path,exp_name,"-rulesPrediction.csv"))
#write(rmCBA@rules, file = "rules-confidences.csv")
message("Results written to disk")
#inspect(rmCBA@rules)
rules_df <- DATAFRAME(rmCBA@rules, separate = TRUE)

#confusion matrix
#https://blog.revolutionanalytics.com/2016/03/com_class_eval_metrics_r.html#perclass
confusion_matrix_df = as.matrix(table(Actual = Target_oracle, Predicted = prediction))
confusion_matrix_df

n = sum(confusion_matrix_df) # number of instances
nc = nrow(confusion_matrix_df) # number of classes
diag = diag(confusion_matrix_df) # number of correctly classified instances per class 
rowsums = apply(confusion_matrix_df, 1, sum) # number of instances per class
colsums = apply(confusion_matrix_df, 2, sum) # number of predictions per class
p = rowsums / n # distribution of instances over the actual classes
q = colsums / n # distribution of instances over the predicted classes
precision = diag / colsums 
recall = diag / rowsums 
f1 = 2 * precision * recall / (precision + recall)
data.frame(precision, recall, f1)
macroPrecision = mean(precision)
macroRecall = mean(recall)
macroF1 = mean(f1)
acc = sum(diag)/n
pred_perf_df <- data.frame(acc,macroPrecision, macroRecall, macroF1)
#ROC curve
confidence_scores <- predict(rmCBA, testFold_X, outputConfidenceScores=TRUE,confScoreType="global")
#target_cba <- droplevels(factor(testFold_Y[[classAtt]],ordered = TRUE,levels=levels(testFold_Y[[classAtt]])))
target_cba <- droplevels(factor(testFold_Y[[classAtt]],ordered = TRUE,levels=levels(Target)))
if (FALSE) {
    pred_cba <- ROCR::prediction(confidence_scores, target_cba)
    roc_cba <- ROCR::performance(pred_cba, "tpr", "fpr")
    ROCR::plot(roc_cba, lwd=2, colorize=TRUE)
    lines(x=c(0, 1), y=c(0, 1), col="black", lwd=1)
    figfilename <- paste(result_path,exp_name, ".png", sep="")
    dev.copy(png,figfilename)
    dev.off()
    message(paste0("roc written to ",figfilename))
    auc <- ROCR::performance(pred_cba, "auc")
    auc <- unlist(auc@y.values)
    auc 
}

