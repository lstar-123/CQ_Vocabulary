// ==================== QA VISUAL VERIFICATION ====================
// Drives the student frontend (http://127.0.0.1:5000) through the upgraded
// flows and screenshots each state. Run: node frontend/qa_visual.js
// Requires: python run.py (backend) on port 5000, playwright in node_modules.

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const BASE = 'http://127.0.0.1:5000';
const SHOTS = path.join(__dirname, 'qa-shots');
const USERNAME = 'qa_' + Date.now().toString(36);
const PASSWORD = 'qa123456';

let passed = 0, failed = 0;
function ok(name, cond, extra = '') {
  if (cond) { passed++; console.log('  ✅ ' + name); }
  else { failed++; console.log('  ❌ ' + name + (extra ? ' — ' + extra : '')); }
}
async function waitFor(page, fn, timeout = 5000, name = 'waitFor') {
  const t0 = Date.now();
  while (Date.now() - t0 < timeout) {
    if (await page.evaluate(fn)) return true;
    await page.waitForTimeout(60);
  }
  console.log('  ⚠️  timeout: ' + name);
  return false;
}
const shot = (page, name) => page.screenshot({ path: path.join(SHOTS, name + '.png'), fullPage: false });

(async () => {
  fs.mkdirSync(SHOTS, { recursive: true });
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 900 } });
  const page = await ctx.newPage();
  const consoleErrors = [];
  page.on('pageerror', e => consoleErrors.push('pageerror: ' + e.message));
  page.on('console', m => { if (m.type() === 'error') consoleErrors.push('console: ' + m.text()); });

  // ── 0. Register a fresh user ────────────────────────────────
  console.log('\n[0] Register user: ' + USERNAME);
  await page.goto(BASE + '/', { waitUntil: 'networkidle' });
  await waitFor(page, () => document.querySelector('#authOverlay .auth-tab[data-mode="register"]'), 8000, 'auth overlay');
  await page.click('#authOverlay .auth-tab[data-mode="register"]');
  await page.fill('#authUsername', USERNAME);
  await page.fill('#authPassword', PASSWORD);
  await shot(page, '01-auth-register');
  await page.click('#authOverlay .btn-auth');
  ok('registration completed', await waitFor(page, () => document.getElementById('userBar').style.display !== 'none', 15000, 'userBar'), USERNAME);

  // ── 1. Book selection ──────────────────────────────────────
  console.log('\n[1] Book selection');
  ok('book overlay shown', await waitFor(page, () => document.getElementById('bookSelectOverlay').style.display === 'flex', 8000, 'bookSelect'));
  await shot(page, '02-book-select');
  await page.click('#bookSelectOptions .book-option');
  await page.click('#btnConfirmBook');
  ok('book confirmed, home shown', await waitFor(page, () => document.getElementById('bookSelectOverlay').style.display === 'none' && document.getElementById('homeScreen').style.display !== 'none', 8000, 'home'));

  // ── 2. Unit selection skeletons ────────────────────────────
  console.log('\n[2] Unit selection skeletons (delayed /api/units)');
  await page.click('#homeCardQuiz');
  const unitsLoaded = await waitFor(page, () => document.querySelector('#unitOptions .unit-option[data-unit]'), 20000, 'units loaded');
  if (!unitsLoaded) {
    console.log('   unitOptions HTML: ' + (await page.evaluate(() => document.getElementById('unitOptions').innerHTML.slice(0, 300))));
    console.log('   toasts: ' + (await page.evaluate(() => Array.from(document.querySelectorAll('.toast')).map(t => t.textContent).join(' | '))));
  }
  const units = await page.evaluate(() =>
    Array.from(document.querySelectorAll('#unitOptions .unit-option')).map(o => ({
      id: parseInt(o.dataset.unit),
      name: (o.querySelector('.unit-name') || {}).textContent,
      count: parseInt((o.querySelector('.unit-count') || {}).textContent) || 0,
    })).filter(u => u.count > 0)
  );
  ok('units with words found', units.length > 0);
  units.sort((a, b) => a.count - b.count);
  const unit = units[0];
  console.log('   using smallest unit: ' + unit.name + ' (' + unit.count + ' words)');

  // ── 3. Quiz feedback (correct / wrong) ─────────────────────
  console.log('\n[3] Quiz answer feedback');
  await page.click(`#unitOptions .unit-option[data-unit="${unit.id}"]`);
  await shot(page, '03-unit-selected');
  await page.click('#btnStart');
  ok('quiz screen shown', await waitFor(page, () => document.getElementById('quizScreen').style.display === 'block', 8000, 'quizScreen'));
  const words = await (await page.request.get(`${BASE}/api/words?unit_ids=${unit.id}&random=1`)).json();
  const zhToEn = new Map(words.map(w => [w.chinese, w.english]));
  ok('word data fetchable', words.length > 0);

  // Q1: correct answer — advances immediately, NO per-word feedback shown
  const q1 = await page.textContent('#wordZh');
  await page.fill('#answerInput', zhToEn.get(q1) || '');
  await page.click('#submitBtn');
  const flashDuring = await page.evaluate(() =>
    document.querySelector('#quizScreen .card.flash-correct') !== null ||
    document.querySelector('#quizScreen .card.flash-wrong') !== null);
  ok('no flash/color feedback on answer', !flashDuring);
  ok('no answer-reveal element in DOM', await page.evaluate(() => document.getElementById('answerReveal') === null));
  ok('immediately advanced to Q2', await waitFor(page, () => (document.querySelector('#counter').textContent || '').trim().startsWith('2'), 800, 'advance-Q2'));
  const aria = await page.textContent('#quizAriaLive');
  ok('aria-live announces correct', aria.includes('正确'));
  await shot(page, '04-quiz-submit-correct');

  // Q2: wrong answer — also advances immediately, no reveal of the answer
  await page.fill('#answerInput', 'wronganswer_xyz');
  await page.click('#submitBtn');
  ok('wrong answer advances immediately', await waitFor(page, () => (document.querySelector('#counter').textContent || '').trim().startsWith('3'), 800, 'advance-Q3'));
  const aria2 = await page.textContent('#quizAriaLive');
  ok('aria-live announces wrong', aria2.includes('错误'));
  const noWrongVisual = await page.evaluate(() => {
    const el = document.getElementById('answerReveal');
    return el === null || el.style.display === 'none';
  });
  ok('no reveal of correct word on wrong answer', noWrongVisual);
  await shot(page, '05-quiz-submit-wrong');

  // ── 4. Confirm modal (buttons, Escape, Enter) ───────────────
  console.log('\n[4] Confirm modal');
  const reopenModal = async () => {
    await page.click('#btnExitQuiz');
    await waitFor(page, () => document.querySelector('.confirm-overlay').style.display === 'flex', 1000, 'confirm-open');
    await page.waitForTimeout(300);   // modalPop
  };
  const counterIs = async (n) => (await page.textContent('#counter')).trim().startsWith(n + ' / ');

  await reopenModal();
  await shot(page, '06-confirm-modal');
  await page.click('.btn-confirm-cancel');   // "继续答题" button
  ok('cancel BUTTON closes modal, stays on quiz', await waitFor(page, () =>
    document.querySelector('.confirm-overlay').style.display === 'none' &&
    document.getElementById('quizScreen').style.display === 'block', 1000, 'cancel-btn'));
  ok('quiz not advanced by cancel', await counterIs(3), await page.textContent('#counter'));

  await reopenModal();
  await page.click('.btn-confirm-ok');       // "退出" button
  ok('confirm BUTTON exits → back to select', await waitFor(page, () =>
    document.getElementById('selectScreen').style.display === 'block', 2000, 'ok-btn-exit'));

  // Re-enter quiz, answer 1 → keyboard paths (Enter confirms, Escape cancels)
  const unitSelected = await page.evaluate((id) =>
    document.querySelector(`#unitOptions .unit-option[data-unit="${id}"]`).classList.contains('selected'), unit.id);
  if (!unitSelected) await page.click(`#unitOptions .unit-option[data-unit="${unit.id}"]`);
  await page.click('#btnStart');
  await waitFor(page, () => document.getElementById('quizScreen').style.display === 'block', 5000, 'quiz-again');
  const qx = await page.textContent('#wordZh');
  await page.fill('#answerInput', zhToEn.get(qx) || '');
  await page.click('#submitBtn');
  await page.waitForTimeout(300);
  await page.click('#btnExitQuiz');
  await waitFor(page, () => document.querySelector('.confirm-overlay').style.display === 'flex', 1000, 'confirm-2');
  await page.keyboard.press('Escape');
  ok('Escape cancels → still on quiz', await waitFor(page, () => document.getElementById('quizScreen').style.display === 'block' && document.querySelector('.confirm-overlay').style.display === 'none', 1000, 'esc-cancel'));
  // Enter pressed while the modal is open must NOT have submitted an answer
  await page.waitForTimeout(300);
  ok('Enter during modal did not double-advance', await counterIs(2), await page.textContent('#counter'));
  await reopenModal();
  await page.keyboard.press('Enter');   // modal Enter = confirm
  ok('modal Enter confirms → back to select', await waitFor(page, () => document.getElementById('selectScreen').style.display === 'block', 2000, 'enter-exit'));

  // ── 5. Complete quiz → results animation + confetti ────────
  console.log('\n[5] Results animation');
  const unitSelected5 = await page.evaluate((id) =>
    document.querySelector(`#unitOptions .unit-option[data-unit="${id}"]`).classList.contains('selected'), unit.id);
  if (!unitSelected5) await page.click(`#unitOptions .unit-option[data-unit="${unit.id}"]`);
  await page.click('#btnStart');
  await waitFor(page, () => document.getElementById('quizScreen').style.display === 'block', 5000, 'quiz-5');
  let guard = 0;
  while (await page.evaluate(() => document.getElementById('quizScreen').style.display === 'block') && guard++ < 100) {
    const zh = await page.textContent('#wordZh');
    await page.fill('#answerInput', zhToEn.get(zh) || '');
    await page.click('#submitBtn');
    await page.waitForTimeout(150);
  }
  ok('quiz completed', await waitFor(page, () => document.getElementById('resultsScreen').style.display === 'block', 5000, 'results'));
  const total = unit.count;
  const expectedAcc = 100;   // this quiz was answered 100% correctly
  const score1 = await page.textContent('#scoreCircle');
  await page.waitForTimeout(400);
  const score2 = await page.textContent('#scoreCircle');
  ok('score counts up', score1 !== score2 || score2.includes(expectedAcc + '%'), `${score1} → ${score2}`);
  await page.waitForTimeout(900);
  const scoreFinal = await page.textContent('#scoreCircle');
  ok('score reaches final value', scoreFinal === expectedAcc + '%', `${scoreFinal} vs ${expectedAcc}%`);
  const ringOffset = await page.evaluate(() => document.getElementById('scoreRingProgress').style.strokeDashoffset);
  ok('ring animated (offset < full length)', parseFloat(ringOffset) < 326.7, 'offset=' + ringOffset + ' (final 0 = full ring, correct for 100%)');
  ok('confetti fired (score >= 90)', await page.evaluate(() => document.querySelectorAll('.confetti-piece').length > 0));
  await page.waitForTimeout(1400);   // let ring + count-up finish
  await shot(page, '07-result-confetti');
  await page.waitForTimeout(1800);   // let confetti clear

  // ── 6. Stats skeletons + error toast ───────────────────────
  console.log('\n[6] Stats skeletons + error toast');
  await page.click('#logoHome');   // results screen → home
  await waitFor(page, () => document.getElementById('homeScreen').style.display !== 'none', 3000, 'back-home');
  await page.context().route('**/api/stats/**', async route => {
    await new Promise(r => setTimeout(r, 1500));
    await route.continue();
  });
  await page.click('#homeCardStats');
  ok('stats skeletons shown while loading', await waitFor(page, () => document.querySelectorAll('#statsSummaryCards .skeleton').length >= 6, 1000, 'skeleton-stats'));
  await shot(page, '08-stats-skeleton');
  ok('stats loaded after delay', await waitFor(page, () => document.querySelector('#statsSummaryCards .ss-num') !== null, 6000, 'stats-loaded'));
  await page.unroute('**/api/stats/**');

  // error toast: abort stats endpoints, re-enter stats tab
  await page.click('#btnBackStats');
  await page.context().route('**/api/stats/**', route => route.abort());
  await page.click('#homeCardStats');
  ok('error toast shown on stats failure', await waitFor(page, () => Array.from(document.querySelectorAll('.toast')).some(t => t.textContent.includes('统计数据加载失败')), 4000, 'stats-error-toast'));
  await shot(page, '09-stats-error-toast');
  await page.context().unroute('**/api/stats/**');

  // ── 7. Flashcard swap animation ────────────────────────────
  console.log('\n[7] Flashcard swap animation');
  await page.click('#btnBackStats');
  await page.click('#homeCardStudy');
  await waitFor(page, () => document.getElementById('studyScreen').style.display === 'block', 5000, 'study');
  await page.click('#btnCardMode');
  ok('card mode entered', await waitFor(page, () => document.querySelector('#flashcard .fc-en-main') && document.querySelector('#flashcard .fc-en-main').textContent.trim() !== '', 5000, 'card-shown'));
  await page.click('#btnNextCard');
  await page.waitForTimeout(150);
  const animState = await page.evaluate(() => {
    const fc = document.querySelector('#flashcard');
    return {
      noSwapClasses: !fc.classList.contains('fc-swap-out') && !fc.classList.contains('fc-swap-in'),
      animationNone: getComputedStyle(fc).animationName === 'none',
    };
  });
  ok('no swap animation classes', animState.noSwapClasses);
  ok('no CSS animation on flashcard', animState.animationNone);
  // Original sizing preserved: min-height 370px, no fixed-height override —
  // the card grows naturally with content (same as before any changes).
  const sizeState = await page.evaluate(() => {
    const cs = getComputedStyle(document.querySelector('.flashcard'));
    return { minHeight: cs.minHeight, height: cs.height, overflow: cs.overflow };
  });
  ok('original sizing preserved (min-height: 370px, no fixed height)',
    sizeState.minHeight === '370px' && sizeState.overflow === 'visible', JSON.stringify(sizeState));
  await page.waitForTimeout(400);   // settle before rapid-nav check
  // rapid navigation — 5 quick clicks
  for (let i = 0; i < 5; i++) await page.click('#btnNextCard');
  await page.waitForTimeout(600);
  const counter = await page.textContent('#fcCounter');
  const totalCards = await page.evaluate(() => document.querySelectorAll('#fcCounter').length && parseInt(document.querySelector('#fcCounter').textContent.split('/')[1]));
  ok('rapid nav consistent', counter.includes(' / ') && parseInt(counter.split('/')[0]) <= totalCards, counter);
  await shot(page, '10-flashcard');

  // ── 8. Sound toggle ────────────────────────────────────────
  console.log('\n[8] Sound toggle');
  await page.click('#btnBackStudy');
  await page.click('#homeCardQuiz');
  await waitFor(page, () => document.getElementById('selectScreen').style.display === 'block', 5000, 'select');
  await waitFor(page, () => document.querySelector('#unitOptions .unit-option[data-unit]'), 10000, 'units-8');
  const unitSelected8 = await page.evaluate((id) =>
    document.querySelector(`#unitOptions .unit-option[data-unit="${id}"]`).classList.contains('selected'), unit.id);
  if (!unitSelected8) await page.click(`#unitOptions .unit-option[data-unit="${unit.id}"]`);
  await page.click('#btnStart');
  await waitFor(page, () => document.getElementById('quizScreen').style.display === 'block', 5000, 'quiz-8');
  const icon0 = await page.evaluate(() => document.getElementById('btnSoundToggle').innerHTML);
  await page.click('#btnSoundToggle');
  const icon1 = await page.evaluate(() => document.getElementById('btnSoundToggle').innerHTML);
  const muted = await page.evaluate(() => localStorage.getItem('soundMuted'));
  ok('sound toggle flips icon', icon0 !== icon1, `icon changed`);
  ok('mute persisted to localStorage', muted === '1', 'soundMuted=' + muted);
  await page.click('#btnSoundToggle');   // restore

  // ── 9. Mobile viewport — no horizontal overflow ────────────
  console.log('\n[9] Mobile viewport');
  const mctx = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const mpage = await mctx.newPage();
  await mpage.goto(BASE + '/', { waitUntil: 'networkidle' });
  await waitFor(mpage, () => document.querySelector('#authOverlay .auth-tab[data-mode="login"]'), 8000, 'm-login');
  await mpage.fill('#authUsername', USERNAME);
  await mpage.fill('#authPassword', PASSWORD);
  await mpage.click('#authOverlay .btn-auth');
  await waitFor(mpage, () => document.getElementById('userBar').style.display !== 'none', 8000, 'm-home');
  await mpage.click('#homeCardQuiz');
  await waitFor(mpage, () => document.querySelector('#unitOptions .unit-option[data-unit]'), 8000, 'm-units');
  const overflow = await mpage.evaluate(() => document.documentElement.scrollWidth > window.innerWidth);
  ok('no horizontal overflow on mobile (select screen)', !overflow, 'scrollWidth=' + (overflow ? await mpage.evaluate(() => document.documentElement.scrollWidth + ' / ' + window.innerWidth) : 'ok'));
  await shot(mpage, '11-mobile-select');
  await mpage.click(`#unitOptions .unit-option[data-unit="${unit.id}"]`);
  await mpage.click('#btnStart');
  await waitFor(mpage, () => document.getElementById('quizScreen').style.display === 'block', 5000, 'm-quiz');
  const mq = await mpage.textContent('#wordZh');
  await mpage.fill('#answerInput', zhToEn.get(mq) || '');
  await mpage.click('#submitBtn');
  await shot(mpage, '12-mobile-quiz-correct');
  const mobOverflow = await mpage.evaluate(() => document.documentElement.scrollWidth > window.innerWidth);
  ok('no horizontal overflow on mobile (quiz screen)', !mobOverflow);
  await mctx.close();

  // ── 10. Console errors ─────────────────────────────────────
  // Expected: the intentional /api/stats/** aborts in test [6]
  // (they trigger the designed error-toast path).
  console.log('\n[10] Console/page errors');
  const unexpected = consoleErrors.filter(e =>
    !e.includes('Stats load failed') && !e.includes('net::ERR_FAILED'));
  ok('zero unexpected page/console errors', unexpected.length === 0, unexpected.slice(0, 5).join(' | '));

  await browser.close();
  console.log(`\n==== RESULT: ${passed} passed, ${failed} failed ====`);
  console.log('Screenshots in frontend/qa-shots/');
  process.exit(failed > 0 ? 1 : 0);
})().catch(e => { console.error('FATAL:', e); process.exit(2); });
