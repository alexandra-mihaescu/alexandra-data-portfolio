set fornitori; #basi di collaudo
set clienti; #clienti

param D {i in fornitori,j in clienti}; #distanza 
param Ur {j in clienti}; #unità richieste
param Ud {i in fornitori}; #unità disponibili

var x {i in fornitori,j in clienti} binary;

minimize distanza: sum {i in fornitori,j in clienti} x[i,j]* D[i,j];

subject to vincolo_1 {i in fornitori}: sum {j in clienti} x[i,j]* Ur[j] <= Ud[i]; #rispettare le unità disponibili
subject to vincolo_2 {j in clienti}: sum {i in fornitori} x[i,j]= 1; #ogni clienti è rifornito solo da un fornitore
subject to vincolo_3 {j in clienti}: sum {i in fornitori} x [i,j] * Ur[j] = Ur[j];

