# Progetto di Reti Logiche
Prova finale del corso di Reti Logiche al Politecnico di Milano nell'Anno Accademico 2023/2024. Valutazione: 29

La specifica richiede di implementare un modulo HW che si interfaccia con una memoria e che, fornita una sequenza di parole di ingresso (specificata dall’indirizzo del primo elemento e dalla lunghezza), la completi sostituendo eventuali zeri con gli ultimi valori letti e associando a ciascuna parola un valore di credibilità adeguato. Questo sarà pari a 31 nel caso in cui non ci sia stata alcuna sostituzione, altrimenti verrà calcolato decrementando il valore della credibilità della parola precedente. La struttura della sequenza di ingresso è illustrata in Figura 1.

<p align="center">
  <img src="https://github.com/user-attachments/assets/d567ead1-533d-4a38-bdf0-72b6e3fd626c" alt="Figura 1" width="150"/>
</p>
<p align="center"><em>Figura 1: struttura della sequenza</em></p>
