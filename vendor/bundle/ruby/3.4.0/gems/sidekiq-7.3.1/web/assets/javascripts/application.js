/* timeago.js - https://github.com/hustcc/timeago.js */
!function(e,t){"object"==typeof module&&module.exports?module.exports=t(e):e.timeago=t(e)}("undefined"!=typeof window?window:this,function(){function e(e){return e instanceof Date?e:isNaN(e)?/^\d+$/.test(e)?new Date(t(e,10)):(e=(e||"").trim().replace(/\.\d+/,"").replace(/-/,"/").replace(/-/,"/").replace(/T/," ").replace(/Z/," UTC").replace(/([\+\-]\d\d)\:?(\d\d)/," $1$2"),new Date(e)):new Date(t(e))}function t(e){return parseInt(e)}function n(e,n,r){n=d[n]?n:d[r]?r:"en";var i=0;for(agoin=e<0?1:0,e=Math.abs(e);e>=l[i]&&i<p;i++)e/=l[i];return e=t(e),i*=2,e>(0===i?9:1)&&(i+=1),d[n](e,i)[agoin].replace("%s",e)}function r(t,n){return n=n?e(n):new Date,(n-e(t))/1e3}function i(e){for(var t=1,n=0,r=e;e>=l[n]&&n<p;n++)e/=l[n],t*=l[n];return r%=t,r=r?t-r:t,Math.ceil(r)}function o(e){return e.getAttribute?e.getAttribute(_):e.attr?e.attr(_):void 0}function u(e,t){function u(o,c,f,s){var d=r(c,e);o.innerHTML=n(d,f,t),a["k"+s]=setTimeout(function(){u(o,c,f,s)},1e3*i(d))}var a={};return t||(t="en"),this.format=function(i,o){return n(r(i,e),o,t)},this.render=function(e,t){void 0===e.length&&(e=[e]);for(var n=0;n<e.length;n++)u(e[n],o(e[n]),t,++c)},this.cancel=function(){for(var e in a)clearTimeout(a[e]);a={}},this.setLocale=function(e){t=e},this}function a(e,t){return new u(e,t)}var c=0,f="second_minute_hour_day_week_month_year".split("_"),s="秒_分钟_小时_天_周_月_年".split("_"),d={en:function(e,t){if(0===t)return["just now","right now"];var n=f[parseInt(t/2)];return e>1&&(n+="s"),[e+" "+n+" ago","in "+e+" "+n]},zh_CN:function(e,t){if(0===t)return["刚刚","片刻后"];var n=s[parseInt(t/2)];return[e+n+"前",e+n+"后"]}},l=[60,60,24,7,365/7/12,12],p=6,_="datetime";return a.register=function(e,t){d[e]=t},a});
!function(s){function n(a){if(e[a])return e[a].exports;var r=e[a]={exports:{},id:a,loaded:!1};return s[a].call(r.exports,r,r.exports,n),r.loaded=!0,r.exports}var e={};return n.m=s,n.c=e,n.p="",n(0)}([function(s,n,e){for(var a=e(1),r=null,t=a.length-1;t>=0;t--)r=a[t],"en"!=r&&"zh_CN"!=r&&timeago.register(r,e(2)("./"+r))},function(s,n){s.exports=["ar","be","bg","ca","da","de","el","en","en_short","es","eu","fr","hu","in_BG","in_HI","in_ID","it","ja","ko","ml","nb_NO","nl","nn_NO","pl","pt_BR","ru","sv","ta","th","uk","vi","zh_CN","zh_TW"]},function(s,n,e){function a(s){return e(r(s))}function r(s){return t[s]||function(){throw new Error("Cannot find module '"+s+"'.")}()}var t={"./ar":3,"./ar.js":3,"./be":4,"./be.js":4,"./bg":5,"./bg.js":5,"./ca":6,"./ca.js":6,"./da":7,"./da.js":7,"./de":8,"./de.js":8,"./el":9,"./el.js":9,"./en":10,"./en.js":10,"./en_short":11,"./en_short.js":11,"./es":12,"./es.js":12,"./eu":13,"./eu.js":13,"./fr":14,"./fr.js":14,"./hu":15,"./hu.js":15,"./in_BG":16,"./in_BG.js":16,"./in_HI":17,"./in_HI.js":17,"./in_ID":18,"./in_ID.js":18,"./it":19,"./it.js":19,"./ja":20,"./ja.js":20,"./ko":21,"./ko.js":21,"./locales":1,"./locales.js":1,"./ml":22,"./ml.js":22,"./nb_NO":23,"./nb_NO.js":23,"./nl":24,"./nl.js":24,"./nn_NO":25,"./nn_NO.js":25,"./pl":26,"./pl.js":26,"./pt_BR":27,"./pt_BR.js":27,"./ru":28,"./ru.js":28,"./sv":29,"./sv.js":29,"./ta":30,"./ta.js":30,"./th":31,"./th.js":31,"./uk":32,"./uk.js":32,"./vi":33,"./vi.js":33,"./zh_CN":34,"./zh_CN.js":34,"./zh_TW":35,"./zh_TW.js":35};a.keys=function(){return Object.keys(t)},a.resolve=r,s.exports=a,a.id=2},function(s,n){function e(s,n){return 1===n?a[s][0]:2==n?a[s][1]:n>=3&&n<=10?a[s][2]:a[s][3]}s.exports=function(s,n){if(0===n)return["منذ لحظات","بعد لحظات"];var a;switch(n){case 1:a=0;break;case 2:case 3:a=1;break;case 4:case 5:a=2;break;case 6:case 7:a=3;break;case 8:case 9:a=4;break;case 10:case 11:a=5;break;case 12:case 13:a=6}var r=e(a,s);return["منذ "+r,"بعد "+r]};var a=[["ثانية","ثانيتين","%s ثوان","%s ثانية"],["دقيقة","دقيقتين","%s دقائق","%s دقيقة"],["ساعة","ساعتين","%s ساعات","%s ساعة"],["يوم","يومين","%s أيام","%s يوماً"],["أسبوع","أسبوعين","%s أسابيع","%s أسبوعاً"],["شهر","شهرين","%s أشهر","%s شهراً"],["عام","عامين","%s أعوام","%s عاماً"]]},function(s,n){function e(s,n,e,a,r){var t=r%10,u=a;return 1===r?u=s:1===t&&r>20?u=n:t>1&&t<5&&(r>20||r<10)&&(u=e),u}var a=e.bind(null,"секунду","%s секунду","%s секунды","%s секунд"),r=e.bind(null,"хвіліну","%s хвіліну","%s хвіліны","%s хвілін"),t=e.bind(null,"гадзіну","%s гадзіну","%s гадзіны","%s гадзін"),u=e.bind(null,"дзень","%s дзень","%s дні","%s дзён"),i=e.bind(null,"тыдзень","%s тыдзень","%s тыдні","%s тыдняў"),o=e.bind(null,"месяц","%s месяц","%s месяцы","%s месяцаў"),d=e.bind(null,"год","%s год","%s гады","%s гадоў");s.exports=function(s,n){switch(n){case 0:return["толькі што","праз некалькі секунд"];case 1:return[a(s)+" таму","праз "+a(s)];case 2:case 3:return[r(s)+" таму","праз "+r(s)];case 4:case 5:return[t(s)+" таму","праз "+t(s)];case 6:case 7:return[u(s)+" таму","праз "+u(s)];case 8:case 9:return[i(s)+" таму","праз "+i(s)];case 10:case 11:return[o(s)+" таму","праз "+o(s)];case 12:case 13:return[d(s)+" таму","праз "+d(s)];default:return["",""]}}},function(s,n){s.exports=function(s,n){return[["току що","съвсем скоро"],["преди %s секунди","след %s секунди"],["преди 1 минута","след 1 минута"],["преди %s минути","след %s минути"],["преди 1 час","след 1 час"],["преди %s часа","след %s часа"],["преди 1 ден","след 1 ден"],["преди %s дни","след %s дни"],["преди 1 седмица","след 1 седмица"],["преди %s седмици","след %s седмици"],["преди 1 месец","след 1 месец"],["преди %s месеца","след %s месеца"],["преди 1 година","след 1 година"],["преди %s години","след %s години"]][n]}},function(s,n){s.exports=function(s,n){return[["fa un moment","d'aquí un moment"],["fa %s segons","d'aquí %s segons"],["fa 1 minut","d'aquí 1 minut"],["fa %s minuts","d'aquí %s minuts"],["fa 1 hora","d'aquí 1 hora"],["fa %s hores","d'aquí %s hores"],["fa 1 dia","d'aquí 1 dia"],["fa %s dies","d'aquí %s dies"],["fa 1 setmana","d'aquí 1 setmana"],["fa %s setmanes","d'aquí %s setmanes"],["fa 1 mes","d'aquí 1 mes"],["fa %s mesos","d'aquí %s mesos"],["fa 1 any","d'aquí 1 any"],["fa %s anys","d'aquí %s anys"]][n]}},function(s,n){s.exports=function(s,n){return[["for et øjeblik siden","om et øjeblik"],["for %s sekunder siden","om %s sekunder"],["for 1 minut siden","om 1 minut"],["for %s minutter siden","om %s minutter"],["for 1 time siden","om 1 time"],["for %s timer siden","om %s timer"],["for 1 dag siden","om 1 dag"],["for %s dage siden","om %s dage"],["for 1 uge siden","om 1 uge"],["for %s uger siden","om %s uger"],["for 1 måned siden","om 1 måned"],["for %s måneder siden","om %s måneder"],["for 1 år siden","om 1 år"],["for %s år siden","om %s år"]][n]}},function(s,n){s.exports=function(s,n){return[["gerade eben","vor einer Weile"],["vor %s Sekunden","in %s Sekunden"],["vor 1 Minute","in 1 Minute"],["vor %s Minuten","in %s Minuten"],["vor 1 Stunde","in 1 Stunde"],["vor %s Stunden","in %s Stunden"],["vor 1 Tag","in 1 Tag"],["vor %s Tagen","in %s Tagen"],["vor 1 Woche","in 1 Woche"],["vor %s Wochen","in %s Wochen"],["vor 1 Monat","in 1 Monat"],["vor %s Monaten","in %s Monaten"],["vor 1 Jahr","in 1 Jahr"],["vor %s Jahren","in %s Jahren"]][n]}},function(s,n){s.exports=function(s,n){return[["μόλις τώρα","σε λίγο"],["%s δευτερόλεπτα πριν","σε %s δευτερόλεπτα"],["1 λεπτό πριν","σε 1 λεπτό"],["%s λεπτά πριν","σε %s λεπτά"],["1 ώρα πριν","σε 1 ώρα"],["%s ώρες πριν","σε %s ώρες"],["1 μέρα πριν","σε 1 μέρα"],["%s μέρες πριν","σε %s μέρες"],["1 εβδομάδα πριν","σε 1 εβδομάδα"],["%s εβδομάδες πριν","σε %s εβδομάδες"],["1 μήνα πριν","σε 1 μήνα"],["%s μήνες πριν","σε %s μήνες"],["1 χρόνο πριν","σε 1 χρόνο"],["%s χρόνια πριν","σε %s χρόνια"]][n]}},function(s,n){s.exports=function(s,n){return[["just now","a while"],["%s seconds ago","in %s seconds"],["1 minute ago","in 1 minute"],["%s minutes ago","in %s minutes"],["1 hour ago","in 1 hour"],["%s hours ago","in %s hours"],["1 day ago","in 1 day"],["%s days ago","in %s days"],["1 week ago","in 1 week"],["%s weeks ago","in %s weeks"],["1 month ago","in 1 month"],["%s months ago","in %s months"],["1 year ago","in 1 year"],["%s years ago","in %s years"]][n]}},function(s,n){s.exports=function(s,n){return[["just now","a while"],["%ss ago","in %ss"],["1m ago","in 1m"],["%sm ago","in %sm"],["1h ago","in 1h"],["%sh ago","in %sh"],["1d ago","in 1d"],["%sd ago","in %sd"],["1w ago","in 1w"],["%sw ago","in %sw"],["1mo ago","in 1mo"],["%smo ago","in %smo"],["1yr ago","in 1yr"],["%syr ago","in %syr"]][n]}},function(s,n){s.exports=function(s,n){return[["justo ahora","en un rato"],["hace %s segundos","en %s segundos"],["hace 1 minuto","en 1 minuto"],["hace %s minutos","en %s minutos"],["hace 1 hora","en 1 hora"],["hace %s horas","en %s horas"],["hace 1 día","en 1 día"],["hace %s días","en %s días"],["hace 1 semana","en 1 semana"],["hace %s semanas","en %s semanas"],["hace 1 mes","en 1 mes"],["hace %s meses","en %s meses"],["hace 1 año","en 1 año"],["hace %s años","en %s años"]][n]}},function(s,n){s.exports=function(s,n){return[["orain","denbora bat barru"],["duela %s segundu","%s segundu barru"],["duela minutu 1","minutu 1 barru"],["duela %s minutu","%s minutu barru"],["duela ordu 1","ordu 1 barru"],["duela %s ordu","%s ordu barru"],["duela egun 1","egun 1 barru"],["duela %s egun","%s egun barru"],["duela aste 1","aste 1 barru"],["duela %s aste","%s aste barru"],["duela hillabete 1","hillabete 1 barru"],["duela %s hillabete","%s hillabete barru"],["duela urte 1","urte 1 barru"],["duela %s urte","%s urte barru"]][n]}},function(s,n){s.exports=function(s,n){return[["à l'instant","dans un instant"],["il y a %s secondes","dans %s secondes"],["il y a 1 minute","dans 1 minute"],["il y a %s minutes","dans %s minutes"],["il y a 1 heure","dans 1 heure"],["il y a %s heures","dans %s heures"],["il y a 1 jour","dans 1 jour"],["il y a %s jours","dans %s jours"],["il y a 1 semaine","dans 1 semaine"],["il y a %s semaines","dans %s semaines"],["il y a 1 mois","dans 1 mois"],["il y a %s mois","dans %s mois"],["il y a 1 an","dans 1 an"],["il y a %s ans","dans %s ans"]][n]}},function(s,n){s.exports=function(s,n){return[["éppen most","éppen most"],["%s másodperce","%s másodpercen belül"],["1 perce","1 percen belül"],["%s perce","%s percen belül"],["1 órája","1 órán belül"],["%s órája","%s órán belül"],["1 napja","1 napon belül"],["%s napja","%s napon belül"],["1 hete","1 héten belül"],["%s hete","%s héten belül"],["1 hónapja","1 hónapon belül"],["%s hónapja","%s hónapon belül"],["1 éve","1 éven belül"],["%s éve","%s éven belül"]][n]}},function(s,n){s.exports=function(s,n){return[["এইমাত্র","একটা সময়"],["%s সেকেন্ড আগে","%s এর সেকেন্ডের মধ্যে"],["1 মিনিট আগে","1 মিনিটে"],["%s এর মিনিট আগে","%s এর মিনিটের মধ্যে"],["1 ঘন্টা আগে","1 ঘন্টা"],["%s ঘণ্টা আগে","%s এর ঘন্টার মধ্যে"],["1 দিন আগে","1 দিনের মধ্যে"],["%s এর দিন আগে","%s এর দিন"],["1 সপ্তাহ আগে","1 সপ্তাহের মধ্যে"],["%s এর সপ্তাহ আগে","%s সপ্তাহের মধ্যে"],["1 মাস আগে","1 মাসে"],["%s মাস আগে","%s মাসে"],["1 বছর আগে","1 বছরের মধ্যে"],["%s বছর আগে","%s বছরে"]][n]}},function(s,n){s.exports=function(s,n){return[["अभी","कुछ समय"],["%s सेकंड पहले","%s सेकंड में"],["1 मिनट पहले","1 मिनट में"],["%s मिनट पहले","%s मिनट में"],["1 घंटे पहले","1 घंटे में"],["%s घंटे पहले","%s घंटे में"],["1 दिन पहले","1 दिन में"],["%s दिन पहले","%s दिनों में"],["1 सप्ताह पहले","1 सप्ताह में"],["%s हफ्ते पहले","%s हफ्तों में"],["1 महीने पहले","1 महीने में"],["%s महीने पहले","%s महीनों में"],["1 साल पहले","1 साल में"],["%s साल पहले","%s साल में"]][n]}},function(s,n){s.exports=function(s,n){return[["baru saja","sebentar"],["%s detik yang lalu","dalam %s detik"],["1 menit yang lalu","dalam 1 menit"],["%s menit yang lalu","dalam %s menit"],["1 jam yang lalu","dalam 1 jam"],["%s jam yang lalu","dalam %s jam"],["1 hari yang lalu","dalam 1 hari"],["%s hari yang lalu","dalam %s hari"],["1 minggu yang lalu","dalam 1 minggu"],["%s minggu yang lalu","dalam %s minggu"],["1 bulan yang lalu","dalam 1 bulan"],["%s bulan yang lalu","dalam %s bulan"],["1 tahun yang lalu","dalam 1 tahun"],["%s tahun yang lalu","dalam %s tahun"]][n]}},function(s,n){s.exports=function(s,n){return[["poco fa","tra poco"],["%s secondi fa","%s secondi da ora"],["un minuto fa","un minuto da ora"],["%s minuti fa","%s minuti da ora"],["un'ora fa","un'ora da ora"],["%s ore fa","%s ore da ora"],["un giorno fa","un giorno da ora"],["%s giorni fa","%s giorni da ora"],["una settimana fa","una settimana da ora"],["%s settimane fa","%s settimane da ora"],["un mese fa","un mese da ora"],["%s mesi fa","%s mesi da ora"],["un anno fa","un anno da ora"],["%s anni fa","%s anni da ora"]][n]}},function(s,n){s.exports=function(s,n){return[["すこし前","すぐに"],["%s秒前","%s秒以内"],["1分前","1分以内"],["%s分前","%s分以内"],["1時間前","1時間以内"],["%s時間前","%s時間以内"],["1日前","1日以内"],["%s日前","%s日以内"],["1週間前","1週間以内"],["%s週間前","%s週間以内"],["1ヶ月前","1ヶ月以内"],["%sヶ月前","%sヶ月以内"],["1年前","1年以内"],["%s年前","%s年以内"]][n]}},function(s,n){s.exports=function(s,n){return[["방금","곧"],["%s초 전","%s초 후"],["1분 전","1분 후"],["%s분 전","%s분 후"],["1시간 전","1시간 후"],["%s시간 전","%s시간 후"],["1일 전","1일 후"],["%s일 전","%s일 후"],["1주일 전","1주일 후"],["%s주일 전","%s주일 후"],["1개월 전","1개월 후"],["%s개월 전","%s개월 후"],["1년 전","1년 후"],["%s년 전","%s년 후"]][n]}},function(s,n){s.exports=function(s,n){return[["ഇപ്പോള്‍","കുറച്ചു മുന്‍പ്"],["%s സെക്കന്റ്‌കള്‍ക്ക് മുന്‍പ്","%s സെക്കന്റില്‍"],["1 മിനിറ്റിനു മുന്‍പ്","1 മിനിറ്റില്‍"],["%s മിനിറ്റുകള്‍ക്ക് മുന്‍പ","%s മിനിറ്റില്‍"],["1 മണിക്കൂറിനു മുന്‍പ്","1 മണിക്കൂറില്‍"],["%s മണിക്കൂറുകള്‍ക്കു മുന്‍പ്","%s മണിക്കൂറില്‍"],["1 ഒരു ദിവസം മുന്‍പ്","1 ദിവസത്തില്‍"],["%s ദിവസങ്ങള്‍ക് മുന്‍പ്","%s ദിവസങ്ങള്‍ക്കുള്ളില്‍"],["1 ആഴ്ച മുന്‍പ്","1 ആഴ്ചയില്‍"],["%s ആഴ്ചകള്‍ക്ക് മുന്‍പ്","%s ആഴ്ചകള്‍ക്കുള്ളില്‍"],["1 മാസത്തിനു മുന്‍പ്","1 മാസത്തിനുള്ളില്‍"],["%s മാസങ്ങള്‍ക്ക് മുന്‍പ്","%s മാസങ്ങള്‍ക്കുള്ളില്‍"],["1 വര്‍ഷത്തിനു  മുന്‍പ്","1 വര്‍ഷത്തിനുള്ളില്‍"],["%s വര്‍ഷങ്ങള്‍ക്കു മുന്‍പ്","%s വര്‍ഷങ്ങള്‍ക്കുല്ല്ളില്‍"]][n]}},function(s,n){s.exports=function(s,n){return[["akkurat nå","om litt"],["%s sekunder siden","om %s sekunder"],["1 minutt siden","om 1 minutt"],["%s minutter siden","om %s minutter"],["1 time siden","om 1 time"],["%s timer siden","om %s timer"],["1 dag siden","om 1 dag"],["%s dager siden","om %s dager"],["1 uke siden","om 1 uke"],["%s uker siden","om %s uker"],["1 måned siden","om 1 måned"],["%s måneder siden","om %s måneder"],["1 år siden","om 1 år"],["%s år siden","om %s år"]][n]}},function(s,n){s.exports=function(s,n){return[["recent","binnenkort"],["%s seconden geleden","binnen %s seconden"],["1 minuut geleden","binnen 1 minuut"],["%s minuten geleden","binnen %s minuten"],["1 uur geleden","binnen 1 uur"],["%s uren geleden","binnen %s uren"],["1 dag geleden","binnen 1 dag"],["%s dagen geleden","binnen %s dagen"],["1 week geleden","binnen 1 week"],["%s weken geleden","binnen %s weken"],["1 maand geleden","binnen 1 maand"],["%s maanden geleden","binnen %s maanden"],["1 jaar geleden","binnen 1 jaar"],["%s jaren geleden","binnen %s jaren"]][n]}},function(s,n){s.exports=function(s,n){return[["nett no","om litt"],["%s sekund sidan","om %s sekund"],["1 minutt sidan","om 1 minutt"],["%s minutt sidan","om %s minutt"],["1 time sidan","om 1 time"],["%s timar sidan","om %s timar"],["1 dag sidan","om 1 dag"],["%s dagar sidan","om %s dagar"],["1 veke sidan","om 1 veke"],["%s veker sidan","om %s veker"],["1 månad sidan","om 1 månad"],["%s månadar sidan","om %s månadar"],["1 år sidan","om 1 år"],["%s år sidan","om %s år"]][n]}},function(s,n){s.exports=function(s,n){var e=[["w tej chwili","za chwilę"],["%s sekund temu","za %s sekund"],["1 minutę temu","za 1 minutę"],["%s minut temu","za %s minut"],["1 godzina temu","za 1 godzinę"],["%s godzin temu","za %s godzin"],["1 dzień temu","za 1 dzień"],["%s dni temu","za %s dni"],["1 tydzień temu","za 1 tydzień"],["%s tygodni temu","za %s tygodni"],["1 miesiąc temu","za 1 miesiąc"],["%s miesiące temu","za %s miesiące"],["1 rok temu","za 1 rok"],["%s lata temu","za %s lata"]],a=s.toString();return 1==n&&(2==a.length&&"1"==a[0]&&"0"!=a[1]||[2,3,4].indexOf(s%10)!=-1||[2,3,4].indexOf(s)!=-1)?["%s sekundy temu","za %s sekundy"]:3!=n||[2,3,4].indexOf(s%10)==-1&&[2,3,4].indexOf(s)==-1?5!=n||[2,3,4].indexOf(s%10)==-1&&[2,3,4].indexOf(s)==-1?9==n&&[2,3,4].indexOf(s)!=-1?["%s tygodnie temu","za %s tygodnie"]:11==n&&(s%10==0||2==a.length&&"1"==a[0]||[1,5,6,7,8,9].indexOf(s%10)!=-1)?["%s miesięcy temu","za %s miesięcy"]:13==n&&(s%10==0||2==a.length&&"1"==a[0]||[1,5,6,7,8,9].indexOf(s%10)!=-1)?["%s lat temu","za %s lat"]:e[n]:["%s godziny temu","za %s godziny"]:["%s minuty temu","za %s minuty"]}},function(s,n){s.exports=function(s,n){return[["agora mesmo","daqui um pouco"],["há %s segundos","em %s segundos"],["há um minuto","em um minuto"],["há %s minutos","em %s minutos"],["há uma hora","em uma hora"],["há %s horas","em %s horas"],["há um dia","em um dia"],["há %s dias","em %s dias"],["há uma semana","em uma semana"],["há %s semanas","em %s semanas"],["há um mês","em um mês"],["há %s meses","em %s meses"],["há um ano","em um ano"],["há %s anos","em %s anos"]][n]}},function(s,n){function e(s,n,e,a,r){var t=r%10,u=a;return 1===r?u=s:1===t&&r>20?u=n:t>1&&t<5&&(r>20||r<10)&&(u=e),u}var a=e.bind(null,"секунду","%s секунду","%s секунды","%s секунд"),r=e.bind(null,"минуту","%s минуту","%s минуты","%s минут"),t=e.bind(null,"час","%s час","%s часа","%s часов"),u=e.bind(null,"день","%s день","%s дня","%s дней"),i=e.bind(null,"неделю","%s неделю","%s недели","%s недель"),o=e.bind(null,"месяц","%s месяц","%s месяца","%s месяцев"),d=e.bind(null,"год","%s год","%s года","%s лет");s.exports=function(s,n){switch(n){case 0:return["только что","через несколько секунд"];case 1:return[a(s)+" назад","через "+a(s)];case 2:case 3:return[r(s)+" назад","через "+r(s)];case 4:case 5:return[t(s)+" назад","через "+t(s)];case 6:return["вчера","завтра"];case 7:return[u(s)+" назад","через "+u(s)];case 8:case 9:return[i(s)+" назад","через "+i(s)];case 10:case 11:return[o(s)+" назад","через "+o(s)];case 12:case 13:return[d(s)+" назад","через "+d(s)];default:return["",""]}}},function(s,n){s.exports=function(s,n){return[["just nu","om en stund"],["%s sekunder sedan","om %s seconder"],["1 minut sedan","om 1 minut"],["%s minuter sedan","om %s minuter"],["1 timme sedan","om 1 timme"],["%s timmar sedan","om %s timmar"],["1 dag sedan","om 1 day"],["%s dagar sedan","om %s days"],["1 vecka sedan","om 1 vecka"],["%s veckor sedan","om %s veckor"],["1 månad sedan","om 1 månad"],["%s månader sedan","om %s månader"],["1 år sedan","om 1 år"],["%s år sedan","om %s år"]][n]}},function(s,n){s.exports=function(s,n){return[["இப்போது","சற்று நேரம் முன்பு"],["%s நொடிக்கு முன்","%s நொடிகளில்"],["1 நிமிடத்திற்க்கு முன்","1 நிமிடத்தில்"],["%s நிமிடத்திற்க்கு முன்","%s நிமிடங்களில்"],["1 மணி நேரத்திற்கு முன்","1 மணி நேரத்திற்குள்"],["%s மணி நேரத்திற்கு முன்","%s மணி நேரத்திற்குள்"],["1 நாளுக்கு முன்","1 நாளில்"],["%s நாட்களுக்கு முன்","%s நாட்களில்"],["1 வாரத்திற்கு முன்","1 வாரத்தில்"],["%s வாரங்களுக்கு முன்","%s வாரங்களில்"],["1 மாதத்திற்கு முன்","1 மாதத்தில்"],["%s மாதங்களுக்கு முன்","%s மாதங்களில்"],["1 வருடத்திற்கு முன்","1 வருடத்தில்"],["%s வருடங்களுக்கு முன்","%s வருடங்களில்"]][n]}},function(s,n){s.exports=function(s,n){return[["เมื่อสักครู่นี้","อีกสักครู่"],["%s วินาทีที่แล้ว","ใน %s วินาที"],["1 นาทีที่แล้ว","ใน 1 นาที"],["%s นาทีที่แล้ว","ใน %s นาที"],["1 ชั่วโมงที่แล้ว","ใน 1 ชั่วโมง"],["%s ชั่วโมงที่แล้ว","ใน %s ชั่วโมง"],["1 วันที่แล้ว","ใน 1 วัน"],["%s วันที่แล้ว","ใน %s วัน"],["1 อาทิตย์ที่แล้ว","ใน 1 อาทิตย์"],["%s อาทิตย์ที่แล้ว","ใน %s อาทิตย์"],["1 เดือนที่แล้ว","ใน 1 เดือน"],["%s เดือนที่แล้ว","ใน %s เดือน"],["1 ปีที่แล้ว","ใน 1 ปี"],["%s ปีที่แล้ว","ใน %s ปี"]][n]}},function(s,n){function e(s,n,e,a,r){var t=r%10,u=a;return 1===r?u=s:1===t&&r>20?u=n:t>1&&t<5&&(r>20||r<10)&&(u=e),u}var a=e.bind(null,"секунду","%s секунду","%s секунди","%s секунд"),r=e.bind(null,"хвилину","%s хвилину","%s хвилини","%s хвилин"),t=e.bind(null,"годину","%s годину","%s години","%s годин"),u=e.bind(null,"день","%s день","%s дні","%s днів"),i=e.bind(null,"тиждень","%s тиждень","%s тиждні","%s тижднів"),o=e.bind(null,"місяць","%s місяць","%s місяці","%s місяців"),d=e.bind(null,"рік","%s рік","%s роки","%s років");s.exports=function(s,n){switch(n){case 0:return["щойно","через декілька секунд"];case 1:return[a(s)+" тому","через "+a(s)];case 2:case 3:return[r(s)+" тому","через "+r(s)];case 4:case 5:return[t(s)+" тому","через "+t(s)];case 6:case 7:return[u(s)+" тому","через "+u(s)];case 8:case 9:return[i(s)+" тому","через "+i(s)];case 10:case 11:return[o(s)+" тому","через "+o(s)];case 12:case 13:return[d(s)+" тому","через "+d(s)];default:return["",""]}}},function(s,n){s.exports=function(s,n){return[["vừa xong","một lúc"],["%s giây trước","trong %s giây"],["1 phút trước","trong 1 phút"],["%s phút trước","trong %s phút"],["1 giờ trước","trong 1 giờ"],["%s giờ trước","trong %s giờ"],["1 ngày trước","trong 1 ngày"],["%s ngày trước","trong %s ngày"],["1 tuần trước","trong 1 tuần"],["%s tuần trước","trong %s tuần"],["1 tháng trước","trong 1 tháng"],["%s tháng trước","trong %s tháng"],["1 năm trước","trong 1 năm"],["%s năm trước","trong %s năm"]][n]}},function(s,n){s.exports=function(s,n){return[["刚刚","片刻后"],["%s秒前","%s秒后"],["1分钟前","1分钟后"],["%s分钟前","%s分钟后"],["1小时前","1小时后"],["%s小时前","%s小时后"],["1天前","1天后"],["%s天前","%s天后"],["1周前","1周后"],["%s周前","%s周后"],["1月前","1月后"],["%s月前","%s月后"],["1年前","1年后"],["%s年前","%s年后"]][n]}},function(s,n){s.exports=function(s,n){return[["剛剛","片刻後"],["%s秒前","%s秒後"],["1分鐘前","1分鐘後"],["%s分鐘前","%s分鐘後"],["1小時前","1小時後"],["%s小時前","%s小時後"],["1天前","1天後"],["%s天前","%s天後"],["1周前","1周後"],["%s周前","%s周後"],["1月前","1月後"],["%s月前","%s月後"],["1年前","1年後"],["%s年前","%s年後"]][n]}}]);

var livePollTimer = null;

var ready = (callback) => {
  if (document.readyState != "loading") callback();
  else document.addEventListener("DOMContentLoaded", callback);
}

ready(addListeners)

function addListeners() {
  document.querySelectorAll(".check_all").forEach(node => {
    node.addEventListener("click", event => {
      node.closest('table').querySelectorAll('input[type=checkbox]').forEach(inp => { inp.checked = !!node.checked; });
    })
  });

  document.querySelectorAll("input[data-confirm]").forEach(node => {
    node.addEventListener("click", event => {
      if (!window.confirm(node.getAttribute("data-confirm"))) {
        event.preventDefault();
        event.stopPropagation();
      }
    })
  })

  document.querySelectorAll("[data-toggle]").forEach(node => {
    node.addEventListener("click", addDataToggleListeners)
  })

  addShiftClickListeners()
  updateFuzzyTimes();
  updateNumbers();
  updateProgressBars();
  setLivePollFromUrl();

  var buttons = document.querySelectorAll(".live-poll");
  if (buttons.length > 0) {
    buttons.forEach(node => {
      node.addEventListener("click", addPollingListeners)
    });

    updateLivePollButton();
    if (localStorage.sidekiqLivePoll == "enabled" && !livePollTimer) {
      scheduleLivePoll();
    }
  }

  document.getElementById("locale-select").addEventListener("change", updateLocale);
}

function addPollingListeners(_event)  {
  if (localStorage.sidekiqLivePoll == "enabled") {
    localStorage.sidekiqLivePoll = "disabled";
    clearTimeout(livePollTimer);
    livePollTimer = null;
  } else {
    localStorage.sidekiqLivePoll = "enabled";
    livePollCallback();
  }

  updateLivePollButton();
}

function addDataToggleListeners(event) {
  var source = event.target || event.srcElement;
  var targName = source.getAttribute("data-toggle");
  var full = document.getElementById(targName);
  if (full.style.display == "block") {
    full.style.display = 'none';
  } else {
    full.style.display = 'block';
  }
}

function addShiftClickListeners() {
  let checkboxes = Array.from(document.querySelectorAll(".shift_clickable"));
  let lastChecked = null;
  checkboxes.forEach(checkbox => {
    checkbox.addEventListener("click", (e) => {
      if (e.shiftKey && lastChecked) {
        let myIndex = checkboxes.indexOf(checkbox);
        let lastIndex = checkboxes.indexOf(lastChecked);
        let [min, max] = [myIndex, lastIndex].sort();
        let newState = checkbox.checked;
        checkboxes.slice(min, max).forEach(c => c.checked = newState);
      }
      lastChecked = checkbox;
    });
  });
}

function updateFuzzyTimes() {
  var locale = document.body.getAttribute("data-locale");
  var parts = locale.split('-');
  if (typeof parts[1] !== 'undefined') {
    parts[1] = parts[1].toUpperCase();
    locale = parts.join('_');
  }

  var t = timeago()
  t.render(document.querySelectorAll('time'), locale);
  t.cancel();
}

function updateNumbers() {
  document.querySelectorAll("[data-nwp]").forEach(node => {
    let number = parseFloat(node.textContent);
    let precision = parseInt(node.dataset["nwp"] || 0);
    if (typeof number === "number") {
      let formatted = number.toLocaleString(undefined, {
        minimumFractionDigits: precision,
        maximumFractionDigits: precision,
      });
      node.textContent = formatted;
    }
  });
}

function setLivePollFromUrl() {
  var url_params = new URL(window.location.href).searchParams

  if (url_params.get("poll") == "true") {
    localStorage.sidekiqLivePoll = "enabled";
  }
}

function updateLivePollButton() {
  if (localStorage.sidekiqLivePoll == "enabled") {
    document.querySelectorAll('.live-poll-stop').forEach(box => { box.style.display = "inline-block" })
    document.querySelectorAll('.live-poll-start').forEach(box => { box.style.display = "none" })
  } else {
    document.querySelectorAll('.live-poll-start').forEach(box => { box.style.display = "inline-block" })
    document.querySelectorAll('.live-poll-stop').forEach(box => { box.style.display = "none" })
  }
}

function livePollCallback() {
  clearTimeout(livePollTimer);

  fetch(window.location.href)
  .then(checkResponse)
  .then(resp => resp.text())
  .then(replacePage)
  .catch(showError)
  .finally(scheduleLivePoll)
}

function checkResponse(resp) {
  if (!resp.ok) {
    throw response.error();
  }
  return resp
}

function scheduleLivePoll() {
  let ti = parseInt(localStorage.sidekiqTimeInterval) || 5000;
  if (ti < 2000) { ti = 2000 }
  livePollTimer = setTimeout(livePollCallback, ti);
}

function replacePage(text) {
  var parser = new DOMParser();
  var doc = parser.parseFromString(text, "text/html");

  var page = doc.querySelector('#page')
  document.querySelector("#page").replaceWith(page)

  var header_status = doc.querySelector('.status')
  document.querySelector('.status').replaceWith(header_status)

  addListeners();
}

function showError(error) {
  console.error(error)
}

function updateLocale(event) {
  event.target.form.submit();
}

function updateProgressBars() {
  document.querySelectorAll('.progress-bar').forEach(bar => { bar.style.width = bar.dataset.width + "%"})
}