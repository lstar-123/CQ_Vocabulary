// ==================== DOM CACHE ====================
// Single source of truth for all DOM element queries.
// All modules import from here — no document.getElementById() elsewhere.

function _(id) { return document.getElementById(id); }

export const DOM = {
  // ── Overlays ──
  get authOverlay()       { return _('authOverlay'); },
  get bookSelectOverlay() { return _('bookSelectOverlay'); },
  get profileOverlay()    { return _('profileOverlay'); },

  // ── Home ──
  get logoHome()          { return _('logoHome'); },
  get userNameDisplay()   { return _('userNameDisplay'); },
  get btnLogout()         { return _('btnLogout'); },
  get homeScreen()        { return _('homeScreen'); },
  get homeCardStudy()     { return _('homeCardStudy'); },
  get homeCardQuiz()      { return _('homeCardQuiz'); },
  get homeCardStats()     { return _('homeCardStats'); },

  // ── Quiz ──
  get selectScreen()      { return _('selectScreen'); },
  get quizScreen()        { return _('quizScreen'); },
  get resultsScreen()     { return _('resultsScreen'); },
  get unitOptions()       { return _('unitOptions'); },
  get btnStart()          { return _('btnStart'); },
  get btnBackSelect()     { return _('btnBackSelect'); },
  get btnBackQuiz()       { return _('btnBackQuiz'); },
  get btnExitQuiz()       { return _('btnExitQuiz'); },
  get submitBtn()         { return _('submitBtn'); },
  get answerInput()       { return _('answerInput'); },
  get btnRestart()        { return _('btnRestart'); },

  // ── Study ──
  get studyScreen()       { return _('studyScreen'); },
  get btnBackStudy()      { return _('btnBackStudy'); },
  get btnCardMode()       { return _('btnCardMode'); },
  get btnListMode()       { return _('btnListMode'); },
  get btnGroupMode()      { return _('btnGroupMode'); },
  get catFilterChips()    { return _('catFilterChips'); },
  get btnSpeakCard()      { return _('btnSpeakCard'); },
  get btnPrevCard()       { return _('btnPrevCard'); },
  get btnNextCard()       { return _('btnNextCard'); },
  get studyContent()      { return _('studyContent'); },
  get studyToolbarInfo()  { return _('studyToolbarInfo'); },

  // ── Group Learning ──
  get groupMode()         { return _('groupMode'); },
  get groupUnitOptions()  { return _('groupUnitOptions'); },
  get groupUnitError()    { return _('groupUnitError'); },
  get groupActive()       { return _('groupActive'); },
  get groupOverview()     { return _('groupOverview'); },
  get groupOverviewTitle(){ return _('groupOverviewTitle'); },
  get groupRoundCards()   { return _('groupRoundCards'); },
  get groupLearningArea() { return _('groupLearningArea'); },
  get groupLearningPhase(){ return _('groupLearningPhase'); },
  get groupWords()        { return _('groupWords'); },
  get groupSpellingPhase(){ return _('groupSpellingPhase'); },
  get groupSpellingInputs(){ return _('groupSpellingInputs'); },
  get groupSpellError()   { return _('groupSpellError'); },
  get groupResult()       { return _('groupResult'); },
  get groupResultIcon()   { return _('groupResultIcon'); },
  get groupResultTitle()  { return _('groupResultTitle'); },
  get groupResultDetail() { return _('groupResultDetail'); },
  get groupResultErrors() { return _('groupResultErrors'); },
  get btnGroupAdvance()   { return _('btnGroupAdvance'); },
  get groupUnitLabel()    { return _('groupUnitLabel'); },
  get groupRoundLabel()   { return _('groupRoundLabel'); },
  get groupCounter()      { return _('groupCounter'); },
  get groupProgressFill() { return _('groupProgressFill'); },
  get groupUnitSelect()   { return _('groupUnitSelect'); },

  // ── Stats ──
  get statsScreen()       { return _('statsScreen'); },
  get btnBackStats()      { return _('btnBackStats'); },
  get statsSummaryCards() { return _('statsSummaryCards'); },
  get trendChart()        { return _('trendChart'); },
  get chartEmpty()        { return _('chartEmpty'); },
  get trendUnitFilter()   { return _('trendUnitFilter'); },
  get historyUnitFilter() { return _('historyUnitFilter'); },
  get historyList()       { return _('historyList'); },
  get historyPagination() { return _('historyPagination'); },

  // ── Profile/Book ──
  get btnConfirmBook()    { return _('btnConfirmBook'); },
  get btnProfileClose()   { return _('btnProfileClose'); },
  get btnProfileSave()    { return _('btnProfileSave'); },
  get bookSelectOptions() { return _('bookSelectOptions'); },
  get bookSelectError()   { return _('bookSelectError'); },
};
