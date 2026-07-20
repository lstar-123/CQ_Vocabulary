// ==================== CARD STATE ====================

let cardWords = [];
let cardIndex = 0;
let showCardGeneration = 0;
let activeCardId = null;

export function getCardWords()        { return cardWords; }
export function setCardWords(words)   { cardWords = words; }

export function getCardIndex()        { return cardIndex; }
export function setCardIndex(index)   { cardIndex = index; }
export function resetCardIndex()      { cardIndex = 0; }

export function getShowCardGeneration()     { return showCardGeneration; }
export function nextShowCardGeneration()    { return ++showCardGeneration; }

export function getActiveCardId()           { return activeCardId; }
export function setActiveCardId(id)         { activeCardId = id; }
