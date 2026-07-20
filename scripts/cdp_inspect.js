// CDP verify: test all three home card clicks with console output
const CDP_PORT = 9224;
const TARGET_URL = 'http://127.0.0.1:5000/';

async function main() {
  const resp = await fetch(`http://127.0.0.1:${CDP_PORT}/json`);
  const pages = await resp.json();
  let wsUrl = pages.find(t => t.type === 'page')?.webSocketDebuggerUrl;
  if (!wsUrl) {
    await fetch(`http://127.0.0.1:${CDP_PORT}/json/new?${encodeURIComponent(TARGET_URL)}`);
    await new Promise(r => setTimeout(r, 2000));
    const resp2 = await fetch(`http://127.0.0.1:${CDP_PORT}/json`);
    wsUrl = resp2.json().find(t => t.type === 'page')?.webSocketDebuggerUrl;
  }
  if (!wsUrl) { console.log('ERROR: no page'); process.exit(1); }

  const ws = new WebSocket(wsUrl);
  let msgId = 0;
  const pending = new Map();
  const consoleLines = [];

  ws.onmessage = (event) => {
    const msg = JSON.parse(event.data.toString());
    const { id, result, error, method, params } = msg;
    if (id && pending.has(id)) {
      const { resolve, reject } = pending.get(id);
      pending.delete(id);
      if (error) reject(new Error(JSON.stringify(error)));
      else resolve(result);
    }
    if (method === 'Runtime.consoleAPICalled') {
      const txt = params.args.map(a => a.value ?? a.description ?? '').join(' ');
      consoleLines.push(txt);
      console.log('[CONSOLE]', txt);
    }
    if (method === 'Runtime.exceptionThrown') {
      const exc = params.exceptionDetails;
      console.log('[EXCEPTION]', exc.text, 'line', exc.lineNumber, '—', (exc.exception?.description||'').substring(0,200));
    }
  };

  function send(method, params = {}) {
    return new Promise((resolve, reject) => {
      const id = ++msgId;
      pending.set(id, { resolve, reject });
      ws.send(JSON.stringify({ id, method, params }));
    });
  }

  await new Promise(r => ws.onopen = r);
  await send('Runtime.enable');
  await send('Page.enable');
  await send('Page.navigate', { url: TARGET_URL });
  await new Promise(r => setTimeout(r, 6000));

  // Check switchTab exists and cards have IDs
  console.log('\n--- Pre-check ---');
  const pre = await send('Runtime.evaluate', {
    expression: `(function(){
      return {
        switchTab: typeof switchTab,
        homeCardStudy: !!document.getElementById('homeCardStudy'),
        homeCardQuiz: !!document.getElementById('homeCardQuiz'),
        homeCardStats: !!document.getElementById('homeCardStats'),
        onclickOnCard: document.getElementById('homeCardStudy')?.getAttribute('onclick')
      };
    })()`,
    returnByValue: true
  });
  console.log(JSON.stringify(pre.result?.value, null, 2));

  // VERIFY 1: Click Study
  console.log('\n========== VERIFY 1: Click 学习 card ==========');
  consoleLines.length = 0;
  await send('Runtime.evaluate', {
    expression: `document.getElementById('homeCardStudy').click()`,
    returnByValue: true
  });
  await new Promise(r => setTimeout(r, 1500));
  const state1 = await send('Runtime.evaluate', {
    expression: `(function(){
      return {
        homeScreen: document.getElementById('homeScreen')?.style.display || '(empty)',
        studyScreen: document.getElementById('studyScreen')?.style.display,
        quizScreen: document.getElementById('quizScreen')?.style.display,
        statsScreen: document.getElementById('statsScreen')?.style.display,
        lastConsoles: ${JSON.stringify(consoleLines)}
      };
    })()`,
    returnByValue: true
  });
  console.log('State:', JSON.stringify(state1.result?.value, null, 2));

  // VERIFY 2: Click Quiz
  console.log('\n========== VERIFY 2: Click 测验 card ==========');
  consoleLines.length = 0;
  await send('Runtime.evaluate', {
    expression: `document.getElementById('homeCardQuiz').click()`,
    returnByValue: true
  });
  await new Promise(r => setTimeout(r, 1500));
  const state2 = await send('Runtime.evaluate', {
    expression: `(function(){
      return {
        homeScreen: document.getElementById('homeScreen')?.style.display || '(empty)',
        studyScreen: document.getElementById('studyScreen')?.style.display,
        selectScreen: document.getElementById('selectScreen')?.style.display,
        statsScreen: document.getElementById('statsScreen')?.style.display,
        lastConsoles: ${JSON.stringify(consoleLines)}
      };
    })()`,
    returnByValue: true
  });
  console.log('State:', JSON.stringify(state2.result?.value, null, 2));

  // VERIFY 3: Click Stats
  console.log('\n========== VERIFY 3: Click 统计 card ==========');
  consoleLines.length = 0;
  await send('Runtime.evaluate', {
    expression: `document.getElementById('homeCardStats').click()`,
    returnByValue: true
  });
  await new Promise(r => setTimeout(r, 1500));
  const state3 = await send('Runtime.evaluate', {
    expression: `(function(){
      return {
        homeScreen: document.getElementById('homeScreen')?.style.display || '(empty)',
        studyScreen: document.getElementById('studyScreen')?.style.display,
        selectScreen: document.getElementById('selectScreen')?.style.display,
        statsScreen: document.getElementById('statsScreen')?.style.display,
        lastConsoles: ${JSON.stringify(consoleLines)}
      };
    })()`,
    returnByValue: true
  });
  console.log('State:', JSON.stringify(state3.result?.value, null, 2));

  // Summary
  console.log('\n========== SUMMARY ==========');
  const sum = await send('Runtime.evaluate', {
    expression: `(function(){
      return {
        switchTabIsFunction: typeof switchTab === 'function',
        allCardsHaveIds: !!document.getElementById('homeCardStudy') && !!document.getElementById('homeCardQuiz') && !!document.getElementById('homeCardStats'),
        noInlineOnclick: !document.getElementById('homeCardStudy')?.getAttribute('onclick')
      };
    })()`,
    returnByValue: true
  });
  console.log(JSON.stringify(sum.result?.value, null, 2));

  ws.close();
  process.exit(0);
}

main().catch(e => { console.error('FATAL:', e.message); process.exit(1); });
