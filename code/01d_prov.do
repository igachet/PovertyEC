/*
01d_prov.do

Derives province (pr) and region (reg: Costa/Sierra/Oriente/Galapagos)
from the city code (ciudad). Called from 01_poverty_line.do.
*/

gen delete=string(ciudad)
gen length=length(delete)

gen zero=0
egen pr= concat(zero delete) 
replace pr=delete if length==6

gen length1=length(pr)
tab length1 
drop delete length zero length1

gen provincia=substr(pr,1,2)
drop pr
gen pr=real(provincia)

drop provincia 


label define pr 1 "Azuay" 2 "Bolivar" 3 "Cañar" 4 "Carchi" 5 "Cotopaxi" 6 "Chimborazo" 7 "El Oro" 8 "Esmeraldas" 9 "Guayas" 10 "Imbabura" 11 "Loja" 12 "Los Ríos" 13 "Manabí" 14 "Morona Santiago" 15 "Napo" 16 "Pastaza" 17 "Pichincha" 18 "Tungurahua" 19 "Zamora Chinchipe" 20 "Galápagos" 21 "Sucumbíos" 22 "Orellana" 23 "Santo Domingo de los Tsáchilas" 24 "Santa Elena" 90 "Zonas no Delimitadas"

label values pr pr
tab pr

gen reg=pr
recode reg (7 8 9 12 13 24 = 1) (1 2 3 4 5 6 10 11 17 18 23 = 2) (14 15 16 19 21 22 = 3) (20 = 4)
label define reg 1 "Costa" 2 "Sierra" 3 "Oriente" 4 "Galápagos"
label values reg reg
