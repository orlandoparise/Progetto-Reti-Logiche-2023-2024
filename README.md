# Progetto di Reti Logiche
Prova finale del corso di Reti Logiche al Politecnico di Milano nell'Anno Accademico 2023/2024. Valutazione: 29

## Specifica
La specifica richiede di implementare un modulo HW che si interfaccia con una memoria e che, fornita una sequenza di parole di ingresso (specificata dall’indirizzo del primo elemento e dalla lunghezza), la completi sostituendo eventuali zeri con gli ultimi valori letti e associando a ciascuna parola un valore di credibilità adeguato. Questo sarà pari a 31 nel caso in cui non ci sia stata alcuna sostituzione, altrimenti verrà calcolato decrementando il valore della credibilità della parola precedente. La struttura della sequenza di ingresso è illustrata in Figura 1.

<p align="center">
  <img src="https://github.com/user-attachments/assets/d567ead1-533d-4a38-bdf0-72b6e3fd626c" alt="Figura 1" width="500"/>
</p>
<p align="center"><em>Figura 1: struttura della sequenza</em></p>

Il valore della credibilità non può essere negativo, dunque nel caso in cui il valore precedente sia uguale a zero non viene effettuato il decremento. Può però succedere che la sequenza inizi con delle parole nulle. Tale eventualità richiede che non vengano fatte sostituzioni e che i valori di credibilità siano posti anch’essi a zero. Inoltre, le parole possono avere valore compreso tra 0 e 255 poiché vengono rappresentate da segnali di un Byte. In Figura 2 è mostrato un esempio di comportamento del sistema appena descritto che, data la sequenza di ingresso fornisce la sequenza finale attesa.

<p align="center">
  <img src="https://github.com/user-attachments/assets/02b531d7-6638-4c44-8877-85a84be5cb4c" alt="Figura 2" width="500"/>
</p>
<p align="center"><em>Figura 2: esempio del comportamento del sistema</em></p>

Nell’esempio riportato le prime due parole sono diverse da zero, perciò, i valori di credibilità vengono posti a 31. La terza parola invece risulta nulla quindi, di conseguenza, il valore di credibilità viene calcolato decrementando il valore della credibilità della parola precedente e quindi risulta pari a 30. Lo stesso accade per le quattro parole successive finché non si riscontra un’altra parola diversa da zero che viene associata a 31 e in questo modo viene ripristinato il valore da decrementare per il calcolo della credibilità associata agli zeri successivi.
