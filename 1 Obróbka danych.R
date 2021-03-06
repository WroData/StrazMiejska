# Deklaracja sciezki do bilbiotek
options(stringsAsFactors = FALSE)

##########################################################################
#### upewnienie si� �e nie ma �adnych pakiet�w za�adowanych ####
gc(reset = TRUE)
#od��czeni wszytkich pakiet�w - stowrzebnuie funkcji
detachAllPackages <- function() {
  basic.packages <- c("package:stats","package:graphics","package:grDevices","package:utils","package:datasets","package:methods","package:base")
  package.list <- search()[ifelse(unlist(gregexpr("package:",search()))==1,TRUE,FALSE)]
  package.list <- setdiff(package.list,basic.packages)
  if (length(package.list)>0)  for (package in package.list) detach(package, character.only=TRUE)
}

detachAllPackages() #wywo�anie funkcji 


##########################################################################
#### za�adowanie pakiet�w ####

library(dplyr)
library(ggplot2)
library(readxl) #do czytania excela
#library(xlsx) #do czytania excela

#library(reshape2)
#library(gridExtra)
#library(grid)

#library(ggmap) #do zbierania wsp�rzednych
#library(sp)  #do zbierania wsp�rzednych

library(lubridate) # do numeru tygodnia
library(stringr) # do funkcji pad

##########################################################################
#### wczytanie danych ####
setwd("D:\\KK\\OneDrive\\Wroclaw w Liczbach\\Gotowe projekty\\stra� miejska")
Mandaty <- read_xlsx(path = "D:\\KK\\OneDrive\\Wroclaw w Liczbach\\Gotowe projekty\\stra� miejska\\Dane Raw\\Wybrane\\Raporty interwencji SM v3.xlsx", 
                     sheet = "Zbiorcze",
                     col_names = TRUE) 
names(Mandaty)[c(2,8, 9)] <- c("Czas_zgloszenia", "Kwota_mandatu", "Czas_zakonczenia")

##########################################################################
#### obr�bka danych ####

#ustalenie kolejnosci dla Miesiac_rok i Tydzien_rok
ORD_Miesiac_rok <- str_pad(paste0(1:12, "-", rep(2016:2018, each = 12)), width = 7, side = "left", pad = "0")
ORD_Tydzien_rok <- str_pad(paste0(0:53, "-", rep(2016:2018, each = 54)), width = 7, side = "left", pad = "0")
ORD_Dzien_tyg   <- c("poniedzia�ek", "wtorek", "�roda", "czwartek", "pi�tek", "sobota", "niedziela")

#sprawdznei czy nie ma jaki� b��d�w
t <-  Mandaty %>%
  filter(is.na(Czas_zakonczenia)) 

Mandaty <- Mandaty  %>%
  arrange(Czas_zakonczenia) %>%
  # filter(!is.na(L.p.)) %>%
  mutate(Adres = gsub("/", "", Miejsce), #usuwanie / na koncu
         Adres = trimws(Adres), #usuwanie zbednych spacji
         Adres = gsub("�", "o", Adres), #polskich znak�w
         Adres = gsub("�", "O", Adres), 
         Adres = gsub("�", "l", Adres), 
         Adres = gsub("�", "L", Adres), 
         Adres = gsub("�", "z", Adres),
         Adres = gsub("�", "Z", Adres),
         Adres = gsub("�", "z", Adres),
         Adres = gsub("�", "Z", Adres),
         Adres = gsub("�", "n", Adres),
         Adres = gsub("�", "N", Adres), 
         Adres = gsub("�", "a", Adres),
         Adres = gsub("�", "A", Adres),
         Adres = gsub("�", "c", Adres), 
         Adres = gsub("�", "C", Adres), 
         Adres = gsub("�", "e", Adres),
         Adres = gsub("�", "E", Adres),
         Adres = gsub("�", "s", Adres),
         Adres = gsub("�", "S", Adres), 
         Adres = gsub(".", " ", Adres, fixed = TRUE), #dopisanie spacji po kropkach, �eby algorytm nie zwariowa�
         #Adres = gsub("\\.", "\\. ", Adres),
         Adres = paste0(Adres, ", Wroclaw"),  #dopisanie Wroc�aw 
         Czas_trwania_interwencji = Czas_zakonczenia - Czas_zgloszenia,
         Rok     = format(Czas_zakonczenia,"%Y") ,
         Miesiac = format(Czas_zakonczenia,"%m") ,
         Tydzien = str_pad(lubridate::isoweek(Czas_zakonczenia), width = 2, side = "left", pad = "0"),
         Dzien   = format(Czas_zakonczenia,"%d %m %y"),
         Dzien_tyg = factor(weekdays(Czas_zakonczenia), levels = ORD_Dzien_tyg),
         Miesiac_rok = factor(paste0(Miesiac, "-", Rok), levels = ORD_Miesiac_rok),
         Tydzien_rok = factor(paste0(Tydzien, "-", Rok), levels = ORD_Tydzien_rok),
         Godzina = hour(Czas_zakonczenia),
         Opis = tolower(Opis),
         Czy_mandat_wystawiony = ifelse(Kwota_mandatu > 0 , 1, 0)
        # Adres = iconv(Adres, from="windows-1250", to="ASCII//TRANSLIT") #usuniecie Polskich znak�W
  ) 


#policzenie grup 
#https://stackoverflow.com/questions/14821064/line-break-when-no-data-in-ggplot2
idx <- c(1, diff(Mandaty$Czas_zakonczenia))
i2 <- c(1, which(idx > 7 * 24 * 60 * 60), nrow(Mandaty)+1)
Mandaty$grp <- rep(1:length(diff(i2)), diff(i2))

max(Mandaty$grp)

##########################################################################
#### Sprawdzenie kategorii zmiennych ####
names(Mandaty)
t <- Mandaty %>%
  group_by(Typ) %>% 
  summarise(ilosc = n()) %>%
  arrange(ilosc)

Mandaty <- Mandaty %>%
  mutate(Typ = case_when(Typ == "ALARM" ~ "Inne",
                         Typ == "KRADZIE�" ~ "Inne",
                         Typ == "KWESTUJ�CY" ~ "Inne",
                         Typ == "NIEPRAWID PARKOWANIE" ~ "Nieprawid�owe parkowanie",
                         Typ == "NISZCZENIE URZ�DZE� PRZECIWPOWODZIOWYCH" ~ "Wandalizm",
                         Typ == "PO�AR" ~ "Inne",
                         Typ == "OSOBA LE��CA" ~ "Inne",
                         Typ == "WYKROCZENIAPIESZYCH" ~ "Inne", 
                         Typ == "ZWIERZ�TA HODOWLANE" ~ "Inne",
                         Typ == "BEZPIECZE�STWO W" ~ "Wykroczenia drogowe",
                         Typ == "BEZPIECZE�STWOW KOMUNIKACJI" ~ "Wykroczenia drogowe",
                         Typ == "DZIKIE ZWIERZ�TA" ~ "Inne",
                         Typ == "POBICIE" ~ "Inne",
                         Typ == "SKARGA" ~ "Inne",
                         Typ == "SK�ADOWANIE ZANIECZYSZCZE�" ~ "Inne",
                         Typ == "UTRUDNIENIE RUCHU MPK" ~ "Inne",
                         Typ == "WYCINKA DRZEW" ~ "Inne",
                         Typ == "Zablokowanywyjazd" ~ "Nieprawid�owe parkowanie",
                         Typ == "BEZPIECZE�STWO WKOMUNIKACJI" ~ "Wykroczenia drogowe",
                         Typ == "NIEWSKAZANIE KIEURJ�CEGO" ~ "Inne",
                         Typ == "NIEPRAWID�OWE" ~ "Nieprawid�owe parkowanie",
                         Typ == "ZAWIADOMIENIE KOMUNIKACYJNE" ~ "Nieprawid�owe parkowanie",
                         Typ == "LE��CA OSOBA" ~ "Inne",
                         Typ == "NIETRZE�WA OSOBA" ~ "Inne",
                         Typ == "BEZDOMNY" ~ "Inne",
                         Typ == "ZDARZENIE DROGOWE" ~ "Wykroczenia drogowe",
                         Typ == "KONTROLA OCHRONA SRODOWISKA" ~ "Inne",
                         Typ == "NISZCZENIE MIENIA" ~ "Wandalizm",
                         Typ == "ZAK��CANIE CISZY NOCNEJ" ~ "Inne",
                         Typ == "NIELEGALNY PO��W RYB" ~ "Inne",
                         Typ == "WRAK POJAZDU" ~ "Ochrona �rodowiska",
                         Typ == "OGNISKO" ~ "Inne",
                         Typ == "�EBRZ�CY" ~ "Inne",
                         Typ == "NIEPRAWID�OWEPARKOWANIE" ~ "Nieprawid�owe parkowanie",
                         Typ == "ZAK��CANIE �ADU I PORZ�DKU" ~ "Inne",
                         Typ == "ZAGRO�ENIE ZDROWIA, �YCIA" ~ "Inne",
                         Typ == "�EBRANIE" ~ "Inne",
                         Typ == "PIEC" ~ "Ochrona �rodowiska",
                         Typ == "LAWETY" ~ "Nieprawid�owe parkowanie",
                         Typ == "PIES" ~ "Inne",
                         Typ == "Zablokowany wyjazd" ~ "Nieprawid�owe parkowanie",
                         Typ == "PALENIE TYTONIU W MIEJSCACH ZABRONIONYCH" ~ "Inne",
                         Typ == "PLAKATY (REKLAMY)" ~ "Inne",
                         Typ == "WYPALANIE, OGNISKO" ~ "Inne",
                         Typ == "WYKROCZENIA PIESZYCH" ~ "Wykroczenia drogowe",
                         Typ == "SPO�YWANIE ALKOHOLU" ~ "Inne",
                         Typ == "NISZCZENIE ZIELENI" ~ "Wandalizm",
                         Typ == "PORZ�DKOWA" ~ "Kontrola czystosci",
                         Typ == "BEZPIECZE�STWO W KOMUNIKACJI" ~ "Wykroczenia drogowe",
                         Typ == "HANDEL" ~ "Handel w miejscu zabronionym",
                         Typ == "BLOKADA" ~ "Nieprawid�owe parkowanie",
                         Typ == "NIEPRAWID�OWE PARKOWANIE" ~ "Nieprawid�owe parkowanie",
                         is.na(Typ) ~ "Inne" ,
                         T ~ "co to? co� innego niz zaplanowa�em"),
         Typ = ifelse(grepl("parkowa", Opis) & Typ == "Wykroczenia drogowe", "Nieprawid�owe parkowanie", Typ),
         Typ = ifelse(grepl("post�j", Opis)  & Typ == "Wykroczenia drogowe", "Nieprawid�owe parkowanie", Typ),
         Typ = ifelse(grepl("przecho", Opis) & Typ == "Wykroczenia drogowe", "Wykroczenia drogowe", Typ))

ORD_Typ <- Mandaty %>%
  group_by(Typ) %>% 
  summarise(ilosc = n()) %>%
  arrange((ilosc)) %>%
  select(Typ) 

Mandaty <- Mandaty %>%
  mutate(Typ = factor(Typ, levels = ORD_Typ$Typ))


##########################################################################
#### zapis ####
save(Mandaty, file = ".\\Dane RData\\1 Dane nt mandat�w.RData")
