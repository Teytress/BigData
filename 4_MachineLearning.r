#Загрузка данных об ирисах в Clickhouse в таблицу db_509579.iris
#install.packages("RClickhouse")
#irisData<-read.csv("https://archive.ics.uci.edu/ml/machine-learning-databases/iris/iris.data", header=FALSE)
#names(irisData)<-c("SepalLength", "SepalWidth", "PetalLength", "PetalWidth", "Species")
#con<-DBI::dbConnect(RClickhouse::clickhouse(), password="PASSWORD", host="kgsu.demo.octonica.com", port=9000)
#DBI::dbSendQuery(con, "use db_509579")
#DBI::dbWriteTable(con, "iris", irisData)
#DBI::dbDisconnect(con)

#Загрузка таблицы db_509579.iris
con<-DBI::dbConnect(RClickhouse::clickhouse(), password="PASSWORD", host="kgsu.demo.octonica.com", port=9000)
res<-DBI::dbGetQuery(con, "select * from db_509579.iris")
DBI::dbDisconnect(con)
#Преобразование данных в корректные типы
res$Species<-as.factor(res$Species)
levels(res$Species)

#Изучениие структуры полученных данных
summary(res)
dim(res)
str(res)
sapply(res, class)
head(res)
levels(res$Species)

#Исследование и визуализирование данных
#Распределение видов ирисов в данном наборе
prct<-prop.table(table(res$Species))*100
cbind(frequency=table(res$Species), percentage=prct)
#Разобьём данные на переменные (x) и отклик (y) 
x<-res[,1:4]
y<-res[,5]
#Визуализируем выборки диаграммой размаха
par(mfrow=c(1,4))
for(i in 1:4)
{
  boxplot(x[,i], main=names(res)[i])  
}
plot(y)

#install.packages("caret")
#install.packages("ellipse")
#install.packages("e1071", dependencies = TRUE)
library(caret)
#Исследуем взаимодействие внутри данных
featurePlot(x=x, y=y, plot="ellipse")
featurePlot(x=x, y=y, plot="box")

#Машинное обучение

#Заранее "отрежем" набор проверочных данных, для проверки качества обученной модели
#возьмём 80% данных
validIndex<-createDataPartition(res$Species, p=0.8, list=FALSE)
#20% данных для проверки качества обученной модели
validation<-res[-validIndex,]
#80% данных для обучения моделей
res<-res[validIndex,]

#Настроим перекрёстную проверку (кроссвалидацию) по 10 блокам
control<-trainControl(method="cv",number=10)
#Проверяемая метрика - точность
metric<-"Accuracy"
#Построение моделей обучения
#LDA (Линейные алгоритмы)
set.seed(13)
fit.lda<-train(Species~., data=res, method="lda", metric=metric, trControl=control)
#CART (Нелинейные алгоритмы)
set.seed(13)
fit.cart<-train(Species~., data=res, method="rpart", metric=metric, trControl=control)
#KNN (Нелинейные алгоритмы)
set.seed(13)
fit.knn<-train(Species~., data=res, method="knn", metric=metric, trControl=control)
#SVM (Сложные алгоритмы)
set.seed(13)
fit.svm<-train(Species~., data=res, method="svmRadial", metric=metric, trControl=control)
#Random Forest (Сложные алгоритмы)
set.seed(13)
fit.rf<-train(Species~., data=res, method="rf", metric=metric, trControl=control)

#Получим оценки контролируемой метрики (точности) для каждого алгоритма
results<-resamples(list(lda=fit.lda, cart=fit.cart, knn=fit.knn, svm=fit.svm, rf=fit.rf))
summary(results)
#Визуализируем полученные оценки
dotplot(results)
#Точнее всех на исследуемых данных оказался линейный алгоритм LDA
print(fit.lda)

#Проверим обученную модель fit.lda на проверочном наборе validation (20% от изначальных данных)
predictions<-predict(fit.lda, validation)
confusionMatrix(predictions, validation$Species)