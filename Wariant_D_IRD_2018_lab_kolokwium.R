# Kolokwium 13.06.2018r.

#Wczytuj? pakiety (nie wszystkie konieczne)
library(readr) # do wczytywania danych
library(data.table) 
library("tidyverse") # do przeksztalcania danych
library("dplyr") #umozliwia manipulacje danych zarowno zapisanych w formie ramek danych
library(ggplot2) #rysowanie wykres?w
library(tidyverse)
library(rpart) # do drzewa
library(rpart.plot) # do rysowania drzewa
library(randomForest) # do budowy (zasadzenia?) lasu losowego
library(caret) # do oceny wyników
library(ROCR) # do krzywej ROC
library("arules") # do znajdowania regul
library("arulesViz") # do wizualizacji regul

# Zad1

# a)

# Tworz? funkcj?
aa <- function(x) {
  if(is.numeric(x) == FALSE) {print("x nie jest warto?ci? numeryczn?")}
  else if(x>=10){return(x^(1/3))}
  else if(x< 10 && x> -10) {return(1/2 * abs(x))}
  else if(x<= -10) {return(log10(abs(x)))} 
}

# Sprawdzam funkcj?
aa("sa")
aa(-10)
aa(-2)
aa(4)
aa(15)
aa(1000)
aa(0)

# b) Liczby ca?kowite od -15 do 15
lcalk <- -15L:15L

# Stosuj? funkcj? na tych liczbach
y <- sapply(lcalk, aa)

# Rysuj? wykres
plot(x=lcalk, y=y, type='p', col = 'blue',
     xlab = "Warto?? od -15 do 15", ylab = "Wynik funkcji",
     main = "funkcja aa na zbiorze lcalk")

# Zad 2

# ?aduj? dane
library(datasets)
data("airquality")
head(airquality)
str(airquality)
library(dplyr)

# Liczebno?? grup, min, max (Sortuj? po miesi?cu)
by_Month <- group_by(airquality, Month)
statystyki <- summarise(by_Month,
          liczebno?? = n(),
          minimalna = min(Wind),
          maksymalna = max(Wind)
)

# Prezentuj? statystyki w konsoli
statystyki

library(ggplot2)

# Rysuj? wykres na podstawie pakietu ggplot2
ggplot(statystyki)   +
  geom_line( 
    aes( x = Month, y = maksymalna)) +
      xlab("Miesiac") +
      ylab("Maksymalna predkosc wiatru") +
      ggtitle("Maksymalna predkosc wiatru w zaleznosci od miesiaca") + 
      ylim(0, 25)


# Zad3

# ?aduj? dane
HRdane <- read.csv("HR_comma_sep.csv")
head(HRdane)
str(HRdane)

# Zmieniam left na typ czynnikowy
HRdane$left <- factor(HRdane$left)
str(HRdane)

# Ustawiam zierno i dziel? na zbi?r ucz?cy i testowy
set.seed(68331)
train_proportion <- 0.75
train_index <- runif(nrow(HRdane)) < train_proportion
train <- HRdane[train_index,]
test <- HRdane[!train_index,]

# Buduj? dwa modele - pierwszy tylko z dwoma zmiennymi niezale?nymi, drugi ze wszystkimi zmiennymi
# niezale?nymi opr?cz left

tree1 <- rpart(left ~ satisfaction_level + salary, 
               data=train,
               method="class")

tree2 <- rpart(left ~.,
               data=train,
               method="class")

# Wygl?d drzew
rpart.plot(tree1, under=FALSE, tweak=1.3, fallen.leaves = TRUE)
rpart.plot(tree2, under=FALSE, tweak=1.3, fallen.leaves = TRUE)

# Tworz? list? z macierzami b??d?w modelu pierwszego oraz drugiego
CM <- list()
CM[["tree1"]] <- table(predict(tree1, new = test, type = "class"), test$left)
CM[["tree2"]] <- table(predict(tree2, new = test, type = "class"), test$left)
# Wygl?d macierzy b?ed?w
CM

# Tworz? funkcj? oceniaj?c? model

EvaluateModel <- function(classif_mx)
{
  # Sciagawka: https://en.wikipedia.org/wiki/Sensitivity_and_specificity#Confusion_matrix
  true_positive <- classif_mx[1,1]
  true_negative <- classif_mx[2,2]
  condition_positive <- sum(classif_mx[ ,1])
  condition_negative <- sum(classif_mx[ ,2])
  # Uzywanie zmiennych pomocniczych o sensownych nazwach
  # ulatwia zrozumienie, co sie dzieje w funkcji
  accuracy <- (true_positive + true_negative) / sum(classif_mx)
  sensitivity <- true_positive / condition_positive
  specificity <- true_negative / condition_negative
  return(list(accuracy = accuracy, 
              sensitivity = sensitivity,
              specificity = specificity))
  # Notacja "accuracy = accuracy" itd. jest potrzebna,
  # zeby elementy listy mialy nazwy.
}

# Oceniam model pierwszy i drugi
EvaluateModel(CM$tree1)
EvaluateModel(CM$tree2)

# Tworz? prognoz? ci?g?? dla obu modeli w celu stworzenia krzywej ROC
prognoza_ciagla <- predict(tree1, newdata = test)
prognoza_ciagla <- as.vector(prognoza_ciagla[,2])

prognoza_ciagla2 <- predict(tree2, newdata = test)
prognoza_ciagla2 <- as.vector(prognoza_ciagla2[,2])

# Tworz? krzyw? ROC - potrzebuje "ciaglej" prognozy
plot(performance(prediction(prognoza_ciagla,test$left),"tpr","fpr"),lwd=2, colorize=T) 
plot(performance(prediction(prognoza_ciagla2,test$left),"tpr","fpr"),lwd=2, colorize=T) 

# Obliczam AUC (Area Under Curve) - pole pod krzywa ROC
performance(prediction(prognoza_ciagla, test$left),"auc")
performance(prediction(prognoza_ciagla2, test$left),"auc")

# Rysuj? wykres: stosunek czu?o?ci do specyficzno?ci (Sensitivity/specificity plots ~ trade-off)
plot(performance(prediction(prognoza_ciagla,test$left),"sens","spec"),lwd=2) 
plot(performance(prediction(prognoza_ciagla2,test$left),"sens","spec"),lwd=2) 

# Rysuj? krzyw? Lift dla obu modeli
plot(performance(prediction(prognoza_ciagla,test$left),"lift","rpp"),lwd=2, col = "darkblue") 
plot(performance(prediction(prognoza_ciagla2,test$left),"lift","rpp"),lwd=2, col = "darkblue")

# Drugi model jest lepszy od pierwszego, poniewa? (w nawiasach warto?ci otrzymane przy
# wywo?ywaniu przeze mnie kodu) : 

# 1. Odznacza si? wy?sz? sprawno?ci? (Accuracy1 = 0.8986339 < Accuracy2 = 0.9639344), 
# czulo?ci? (Sensitivity1 = 0.9589671 < Sensitivity2 = 0.9805447) oraz specyficzno?ci? 
# (Specificity1 = 0.6938776 < Specificity2 = 0.907563)

# 2. Krzywa ROC dla drugiego modelu jest nad krzyw? ROC dla pierwszego modelu

# 3. Pole pod krzyw? ROC drugiego modelu jest wi?ksze ni? to pod krzyw? ROC pierwszego
# modelu AUC1 = 0.8343477 < AUC2 = 0.9661865

# 4. Krzywa zale?no?ci pomi?dzy czu?o?ci?, a specyficzno?ci? drugiego modelu jest ponad t?
# sam? krzyw? z modelu pierwszego

# 5. Drugi model odznacza si? lepsz? krzyw? Lift, czyli og?lny zysk z wykorzystania modelu drugiego
# w stosunku do modelu losowego jest wi?kszy ni? ten sam zystk z wykorzystania modelu pierwszego

# Zad 4

# Wczytuje dane
dane4na <- read.csv("HR_comma_sep.csv")
head(dane4na)
str(dane4na)
summarise(dane4na)
# Pozbywam si? NA
dane4 <- na.omit(dane4na)
# Tworz? kolumn? ze ?redniej liczbie godzin pracy w ci?gu dnia i dodaj? j? do danych
dane4 <- mutate(dane4,
       average_daily_hours = average_montly_hours/21)
str(dane4)

# Tworz? tabel? spe?niaj?c? wymagania zadania
tabela <- dane4 %>%
  select(sales, salary, average_daily_hours) %>%
  group_by(sales, salary) %>%
  summarise(
    ?redniagodzindni = round(average_daily_hours),2) %>%
  arrange(?redniagodzindni)

# Wy?wietlam posortowan? tabel?
tabela


# Zad 5

# Wczytuj? dane
dane5na <- read.csv("HR_comma_sep.csv")
head(dane5na)
str(dane5na)
summarise(dane5na)
# Pozbywam si? NA
dane5 <- na.omit(dane5na)

# Zmieniam warto?ci w kolumnie left na typ czynnikowy
dane5$left <- factor(dane5$left)
str(dane5)

# Ustawiam ziarno i tworz? zbi?r ucz?cy i testowy
set.seed(68331)
train_proportion <- 0.75
train_index <- runif(nrow(HRdane)) < train_proportion
train <- HRdane[train_index,]
test <- HRdane[!train_index,]

library(randomForest)

# Tworz? las losowy
rf <- randomForest(left ~., data = train)

# Sprawdzam, co odegra?o najwi?ksz? rol?
varImpPlot(rf) 

# Tworz? macierz b?edu
Macierzbledu <- rf_classif_mx <- table(predict(rf, new = test, type = "class"), test$left)
# Wywo?uj? macierz b?edu
Macierzbledu

# Rysuj? krzyw? ROC dla lasu
forecast <- predict(rf, newdata = test, type = "prob")[,2]
plottingData <- prediction(forecast, test$left)
plot(performance(plottingData,"tpr","fpr"),lwd=2, colorize=T)
# Wyliczam AUC dla tego lasu
AUC <- performance(plottingData,"auc")@y.values[[1]]
AUC
# AUC wynosi w moim przypadku 0.9902431

# Tworz? krzyw? Lift
plot(performance(plottingData ,"lift","rpp"),lwd=2, col = "darkblue") 
