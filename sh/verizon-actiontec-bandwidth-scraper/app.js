'use strict';

var fs = require('fs');
const puppeteer = require('puppeteer');

const userNm = 'YOUR_ROUTER_USER_NAME'; // usually admin
const password = 'YOUR_ROUTER_PASSWORD';
const routerAdminUrl = 'http://192.168.1.1';

(async () => {
  async function clickLink(page, text) {
    const doIt = () => {
      return page.evaluate(async (text) => {
        return await new Promise(resolve => {
          let a;
          let elements = document.getElementsByTagName("a");
          for (let element of elements) {
            if (element.innerHTML.includes(text)) {
              a = element;
            }
          }

          if (a) {
            a.click();
            resolve(0);
          } else {
            console.log('ERROR - cannot find link with text "' + text + '".');
            resolve(1);
          }

        });
      }, text);
    };

    await sleep(500);
    const result = await doIt();
    await page.waitFor('form[name=form_contents]', { waitUntil: 'networkidle2' });
    await sleep(500);

    return result;
  }

  function sleep(ms) {
    return new Promise(function (resolve) {
      setTimeout(resolve, ms);
    });
  }

  async function getData() {
    const browser = await puppeteer.launch();

    try {
      const page = await browser.newPage();
      page.on('console', consoleObj => console.log(consoleObj.text()));

      console.log('Open page.');
      await page.goto(routerAdminUrl, { waitUntil: 'networkidle2' });

      // Login 
      console.log('Logging in.');
      await page.waitFor('input[name=user_name]');
      await page.type('input[name=user_name]', userNm, { delay: 100 });
      await page.type('input[name^=password_]', password);

      await page.click('a', { waitUntil: 'networkidle2' });
      await page.waitFor('form[name=form_contents]', { delay: 250 });

      const loggedIn = await page.evaluate(() => {
        const tables = document.getElementsByTagName('table');
        for (let table of tables) {
          if (table.innerText.includes('Please wait until open sessions expire.')) {
            return table.innerText;
          }
        }

        return 'OK';
      });

      if (loggedIn !== 'OK') {
        throw loggedIn;
      }

      // Logged in

      await clickLink(page, 'Monitoring');
      await clickLink(page, 'Advanced');
      await clickLink(page, 'Yes');
      await clickLink(page, 'Traffic');

      let received1 = 0; // received bytes
      let sent1 = 0;
      let time1 = new Date();
      for (let i = 0; i < 10000; i++) {
        let time2 = new Date();
        if (i > 0) { await clickLink(page, 'Refresh'); }

        // Parse table get get data out
        const data = await page.evaluate(() => {
          const tables = document.getElementsByTagName('table');
          for (let table of tables) {
            if (table.querySelectorAll('table').length === 0 && table.innerHTML.includes('PPPoE')) {
              const tds = Array.from(table.querySelectorAll('tr td'));
              return tds.map(td => td.innerText);
            }
          }
        });

        if (data) {
          const received2 = parseInt(data[51]);
          const sent2 = parseInt(data[57]);

          if (received1 != 0) {
            const elapsedMs = time2 - time1;
            let received = received2 - received1;
            let sent = sent2 - sent1;
            const MAX_INT = 4294967295;

            // Check for int wrap-around
            if (received < 0) {
              received = (MAX_INT - received1) + received2;
            }
            if (sent < 0) {
              sent = (MAX_INT - sent1) + sent2;
            }

            // convert to Mbps
            const receiveMbps = (received * 8 / (1024 * 1024)) / (elapsedMs / 1000);
            const sendMbps = (sent * 8 / (1024 * 1024)) / (elapsedMs / 1000);

            const logMsg = time2.toISOString() + ' rx=' + receiveMbps.toFixed(2) + ' tx=' + sendMbps.toFixed(2) + ' rxRaw=' + received2 + ' txRaw=' + sent2
            console.log(logMsg);

            fs.appendFileSync('d:/scripts/logs/bandwidth.log', logMsg + '\r\n');
          }

          received1 = received2;
          sent1 = sent2;
          time1 = time2;
        }
        else {
          console.error('Cannot find data.');
        }

        if (i === 0) {
          await sleep(1000);
        } else {
          await sleep(60000);
        }
      }

      // Logout
      console.log('Logging out');
      await page.click('a[name=logout', { waitUntil: 'networkidle2' });
      await browser.close();
    }
    catch (error) {
      console.error('ERROR: ' + error);
      if (browser) {
        browser.close();
      }
    }
  }

  //-----
  // MAIN

  while (true) {
    await getData();
  }

})();