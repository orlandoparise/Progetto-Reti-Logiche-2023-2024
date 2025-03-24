# Progetto di Reti Logiche
Prova finale del corso di Reti Logiche al Politecnico di Milano nell'Anno Accademico 2023/2024. Valutazione: 29

## Descrizione
Il progetto richiede di implementare un modulo HW che si interfaccia con una memoria e che, fornita una sequenza di parole di ingresso (specificata dall’indirizzo del primo elemento e dalla lunghezza), la completi sostituendo eventuali zeri con gli ultimi valori letti e associando a ciascuna parola un valore di credibilità adeguato. Questo sarà pari a 31 nel caso in cui non ci sia stata alcuna sostituzione, altrimenti verrà calcolato decrementando il valore della credibilità della parola precedente.

## Implementazione
L’implementazione della specifica ha portato alla progettazione di una macchina a stati finiti, la quale sequenzialmente completa la sequenza di ingresso. Inizialmente, il numero di stati era limitato a quattro fasi: reset del sistema, attesa del segnale di start, lettura della parola, scrittura della credibilità. In un momento successivo, la necessità di poter gestire le parole nulle e la difficoltà nel comunicare con la memoria in singoli cicli di clock ha arricchito il numero di stati.

## Sviluppatori
[Giovanni Pachera](https://github.com/giovannipachera)  
[Orlando Francesco Parise](https://github.com/orlandoparise)