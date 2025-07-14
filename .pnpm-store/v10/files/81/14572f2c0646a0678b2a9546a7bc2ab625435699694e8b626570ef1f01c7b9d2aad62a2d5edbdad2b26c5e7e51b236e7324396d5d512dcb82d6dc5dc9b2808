var fa = {};
function Xa(w) {
  return new Int8Array(w);
}
function ma(w) {
  return new Int16Array(w);
}
function ba(w) {
  return new Int32Array(w);
}
function ca(w) {
  return new Float32Array(w);
}
function Ya(w) {
  return new Float64Array(w);
}
function Sa(w) {
  if (w.length == 1)
    return ca(w[0]);
  var Z = w[0];
  w = w.slice(1);
  for (var X = [], z = 0; z < Z; z++)
    X.push(Sa(w));
  return X;
}
function da(w) {
  if (w.length == 1)
    return ba(w[0]);
  var Z = w[0];
  w = w.slice(1);
  for (var X = [], z = 0; z < Z; z++)
    X.push(da(w));
  return X;
}
function Aa(w) {
  if (w.length == 1)
    return ma(w[0]);
  var Z = w[0];
  w = w.slice(1);
  for (var X = [], z = 0; z < Z; z++)
    X.push(Aa(w));
  return X;
}
function Ra(w) {
  if (w.length == 1)
    return new Array(w[0]);
  var Z = w[0];
  w = w.slice(1);
  for (var X = [], z = 0; z < Z; z++)
    X.push(Ra(w));
  return X;
}
var xa = {};
xa.fill = function(w, Z, X, z) {
  if (arguments.length == 2)
    for (var u0 = 0; u0 < w.length; u0++)
      w[u0] = arguments[1];
  else
    for (var u0 = Z; u0 < X; u0++)
      w[u0] = z;
};
var W1 = {};
W1.arraycopy = function(w, Z, X, z, u0) {
  for (var W = Z + u0; Z < W; )
    X[z++] = w[Z++];
};
W1.out = {};
W1.out.println = function(w) {
  console.log(w);
};
W1.out.printf = function() {
  console.log.apply(console, arguments);
};
var se = {};
se.SQRT2 = 1.4142135623730951;
se.FAST_LOG10 = function(w) {
  return Math.log10(w);
};
se.FAST_LOG10_X = function(w, Z) {
  return Math.log10(w) * Z;
};
function B1(w) {
  this.ordinal = w;
}
B1.short_block_allowed = new B1(0);
B1.short_block_coupled = new B1(1);
B1.short_block_dispensed = new B1(2);
B1.short_block_forced = new B1(3);
var Ma = {};
Ma.MAX_VALUE = 34028235e31;
function u1(w) {
  this.ordinal = w;
}
u1.vbr_off = new u1(0);
u1.vbr_mt = new u1(1);
u1.vbr_rh = new u1(2);
u1.vbr_abr = new u1(3);
u1.vbr_mtrh = new u1(4);
u1.vbr_default = u1.vbr_mtrh;
var qa = function(w) {
}, Q0 = {
  System: W1,
  VbrMode: u1,
  Float: Ma,
  ShortBlock: B1,
  Util: se,
  Arrays: xa,
  new_array_n: Ra,
  new_byte: Xa,
  new_double: Ya,
  new_float: ca,
  new_float_n: Sa,
  new_int: ba,
  new_int_n: da,
  new_short: ma,
  new_short_n: Aa,
  assert: qa
}, ce, De;
function Da() {
  if (De)
    return ce;
  De = 1;
  var w = Q0, Z = w.System, X = w.Util, z = w.Arrays, u0 = w.new_float, W = t1();
  function Q() {
    var D = [
      -0.1482523854003001,
      32.308141959636465,
      296.40344946382766,
      883.1344870032432,
      11113.947376231741,
      1057.2713659324597,
      305.7402417275812,
      30.825928907280012,
      /* 15 */
      3.8533188138216365,
      59.42900443849514,
      709.5899960123345,
      5281.91112291017,
      -5829.66483675846,
      -817.6293103748613,
      -76.91656988279972,
      -4.594269939176596,
      0.9063471690191471,
      0.1960342806591213,
      -0.15466694054279598,
      34.324387823855965,
      301.8067566458425,
      817.599602898885,
      11573.795901679885,
      1181.2520595540152,
      321.59731579894424,
      31.232021761053772,
      /* 14 */
      3.7107095756221318,
      53.650946155329365,
      684.167428119626,
      5224.56624370173,
      -6366.391851890084,
      -908.9766368219582,
      -89.83068876699639,
      -5.411397422890401,
      0.8206787908286602,
      0.3901806440322567,
      -0.16070888947830023,
      36.147034243915876,
      304.11815768187864,
      732.7429163887613,
      11989.60988270091,
      1300.012278487897,
      335.28490093152146,
      31.48816102859945,
      /* 13 */
      3.373875931311736,
      47.232241542899175,
      652.7371796173471,
      5132.414255594984,
      -6909.087078780055,
      -1001.9990371107289,
      -103.62185754286375,
      -6.104916304710272,
      0.7416505462720353,
      0.5805693545089249,
      -0.16636367662261495,
      37.751650073343995,
      303.01103387567713,
      627.9747488785183,
      12358.763425278165,
      1412.2779918482834,
      346.7496836825721,
      31.598286663170416,
      /* 12 */
      3.1598635433980946,
      40.57878626349686,
      616.1671130880391,
      5007.833007176154,
      -7454.040671756168,
      -1095.7960341867115,
      -118.24411666465777,
      -6.818469345853504,
      0.6681786379192989,
      0.7653668647301797,
      -0.1716176790982088,
      39.11551877123304,
      298.3413246578966,
      503.5259106886539,
      12679.589408408976,
      1516.5821921214542,
      355.9850766329023,
      31.395241710249053,
      /* 11 */
      2.9164211881972335,
      33.79716964664243,
      574.8943997801362,
      4853.234992253242,
      -7997.57021486075,
      -1189.7624067269965,
      -133.6444792601766,
      -7.7202770609839915,
      0.5993769336819237,
      0.9427934736519954,
      -0.17645823955292173,
      40.21879108166477,
      289.9982036694474,
      359.3226160751053,
      12950.259102786438,
      1612.1013903507662,
      362.85067106591504,
      31.045922092242872,
      /* 10 */
      2.822222032597987,
      26.988862316190684,
      529.8996541764288,
      4671.371946949588,
      -8535.899136645805,
      -1282.5898586244496,
      -149.58553632943463,
      -8.643494270763135,
      0.5345111359507916,
      1.111140466039205,
      -0.36174739330527045,
      41.04429910497807,
      277.5463268268618,
      195.6386023135583,
      13169.43812144731,
      1697.6433561479398,
      367.40983966190305,
      30.557037410382826,
      /* 9 */
      2.531473372857427,
      20.070154905927314,
      481.50208566532336,
      4464.970341588308,
      -9065.36882077239,
      -1373.62841526722,
      -166.1660487028118,
      -9.58289321133207,
      0.4729647758913199,
      1.268786568327291,
      -0.36970682634889585,
      41.393213350082036,
      261.2935935556502,
      12.935476055240873,
      13336.131683328815,
      1772.508612059496,
      369.76534388639965,
      29.751323653701338,
      2.4023193045459172,
      13.304795348228817,
      430.5615775526625,
      4237.0568611071185,
      -9581.931701634761,
      -1461.6913552409758,
      -183.12733958476446,
      -10.718010163869403,
      0.41421356237309503,
      /* tan(PI/8) */
      1.414213562373095,
      -0.37677560326535325,
      41.619486213528496,
      241.05423794991074,
      -187.94665032361226,
      13450.063605744153,
      1836.153896465782,
      369.4908799925761,
      29.001847876923147,
      /* 7 */
      2.0714759319987186,
      6.779591200894186,
      377.7767837205709,
      3990.386575512536,
      -10081.709459700915,
      -1545.947424837898,
      -200.3762958015653,
      -11.864482073055006,
      0.3578057213145241,
      1.546020906725474,
      -0.3829366947518991,
      41.1516456456653,
      216.47684307105183,
      -406.1569483347166,
      13511.136535077321,
      1887.8076599260432,
      367.3025214564151,
      28.136213436723654,
      /* 6 */
      1.913880671464418,
      0.3829366947518991,
      323.85365704338597,
      3728.1472257487526,
      -10561.233882199509,
      -1625.2025997821418,
      -217.62525175416,
      -13.015432208941645,
      0.3033466836073424,
      1.66293922460509,
      -0.5822628872992417,
      40.35639251440489,
      188.20071124269245,
      -640.2706748618148,
      13519.21490106562,
      1927.6022433578062,
      362.8197642637487,
      26.968821921868447,
      /* 5 */
      1.7463817695935329,
      -5.62650678237171,
      269.3016715297017,
      3453.386536448852,
      -11016.145278780888,
      -1698.6569643425091,
      -234.7658734267683,
      -14.16351421663124,
      0.2504869601913055,
      1.76384252869671,
      -0.5887180101749253,
      39.23429103868072,
      155.76096234403798,
      -889.2492977967378,
      13475.470561874661,
      1955.0535223723712,
      356.4450994756727,
      25.894952980042156,
      /* 4 */
      1.5695032905781554,
      -11.181939564328772,
      214.80884394039484,
      3169.1640829158237,
      -11443.321309975563,
      -1765.1588461316153,
      -251.68908574481912,
      -15.49755935939164,
      0.198912367379658,
      1.847759065022573,
      -0.7912582233652842,
      37.39369355329111,
      119.699486012458,
      -1151.0956593239027,
      13380.446257078214,
      1970.3952110853447,
      348.01959814116185,
      24.731487364283044,
      /* 3 */
      1.3850130831637748,
      -16.421408865300393,
      161.05030052864092,
      2878.3322807850063,
      -11838.991423510031,
      -1823.985884688674,
      -268.2854986386903,
      -16.81724543849939,
      0.1483359875383474,
      1.913880671464418,
      -0.7960642926861912,
      35.2322109610459,
      80.01928065061526,
      -1424.0212633405113,
      13235.794061869668,
      1973.804052543835,
      337.9908651258184,
      23.289159354463873,
      1.3934255946442087,
      -21.099669467133474,
      108.48348407242611,
      2583.700758091299,
      -12199.726194855148,
      -1874.2780658979746,
      -284.2467154529415,
      -18.11369784385905,
      0.09849140335716425,
      1.961570560806461,
      -0.998795456205172,
      32.56307803611191,
      36.958364584370486,
      -1706.075448829146,
      13043.287458812016,
      1965.3831106103316,
      326.43182772364605,
      22.175018750622293,
      1.198638339011324,
      -25.371248002043963,
      57.53505923036915,
      2288.41886619975,
      -12522.674544337233,
      -1914.8400385312243,
      -299.26241273417224,
      -19.37805630698734,
      0.04912684976946725,
      1.990369453344394,
      0.035780907 * X.SQRT2 * 0.5 / 2384e-9,
      0.017876148 * X.SQRT2 * 0.5 / 2384e-9,
      3134727e-9 * X.SQRT2 * 0.5 / 2384e-9,
      2457142e-9 * X.SQRT2 * 0.5 / 2384e-9,
      971317e-9 * X.SQRT2 * 0.5 / 2384e-9,
      218868e-9 * X.SQRT2 * 0.5 / 2384e-9,
      101566e-9 * X.SQRT2 * 0.5 / 2384e-9,
      13828e-9 * X.SQRT2 * 0.5 / 2384e-9,
      12804.797818791945,
      1945.5515939597317,
      313.4244966442953,
      20.801593959731544,
      1995.1556208053692,
      9.000838926174497,
      -29.20218120805369
      /* 2.384e-06/2.384e-06 */
    ], g = 12, f0 = 36, A = [
      [
        2382191739347913e-28,
        6423305872147834e-28,
        9400849094049688e-28,
        1122435026096556e-27,
        1183840321267481e-27,
        1122435026096556e-27,
        940084909404969e-27,
        6423305872147839e-28,
        2382191739347918e-28,
        5456116108943412e-27,
        4878985199565852e-27,
        4240448995017367e-27,
        3559909094758252e-27,
        2858043359288075e-27,
        2156177623817898e-27,
        1475637723558783e-27,
        8371015190102974e-28,
        2599706096327376e-28,
        -5456116108943412e-27,
        -4878985199565852e-27,
        -4240448995017367e-27,
        -3559909094758252e-27,
        -2858043359288076e-27,
        -2156177623817898e-27,
        -1475637723558783e-27,
        -8371015190102975e-28,
        -2599706096327376e-28,
        -2382191739347923e-28,
        -6423305872147843e-28,
        -9400849094049696e-28,
        -1122435026096556e-27,
        -1183840321267481e-27,
        -1122435026096556e-27,
        -9400849094049694e-28,
        -642330587214784e-27,
        -2382191739347918e-28
      ],
      [
        2382191739347913e-28,
        6423305872147834e-28,
        9400849094049688e-28,
        1122435026096556e-27,
        1183840321267481e-27,
        1122435026096556e-27,
        9400849094049688e-28,
        6423305872147841e-28,
        2382191739347918e-28,
        5456116108943413e-27,
        4878985199565852e-27,
        4240448995017367e-27,
        3559909094758253e-27,
        2858043359288075e-27,
        2156177623817898e-27,
        1475637723558782e-27,
        8371015190102975e-28,
        2599706096327376e-28,
        -5461314069809755e-27,
        -4921085770524055e-27,
        -4343405037091838e-27,
        -3732668368707687e-27,
        -3093523840190885e-27,
        -2430835727329465e-27,
        -1734679010007751e-27,
        -974825365660928e-27,
        -2797435120168326e-28,
        0,
        0,
        0,
        0,
        0,
        0,
        -2283748241799531e-28,
        -4037858874020686e-28,
        -2146547464825323e-28
      ],
      [
        0.1316524975873958,
        /* win[SHORT_TYPE] */
        0.414213562373095,
        0.7673269879789602,
        1.091308501069271,
        /* tantab_l */
        1.303225372841206,
        1.56968557711749,
        1.920982126971166,
        2.414213562373094,
        3.171594802363212,
        4.510708503662055,
        7.595754112725146,
        22.90376554843115,
        0.984807753012208,
        /* cx */
        0.6427876096865394,
        0.3420201433256688,
        0.9396926207859084,
        -0.1736481776669303,
        -0.7660444431189779,
        0.8660254037844387,
        0.5,
        -0.5144957554275265,
        /* ca */
        -0.4717319685649723,
        -0.3133774542039019,
        -0.1819131996109812,
        -0.09457419252642064,
        -0.04096558288530405,
        -0.01419856857247115,
        -0.003699974673760037,
        0.8574929257125442,
        /* cs */
        0.8817419973177052,
        0.9496286491027329,
        0.9833145924917901,
        0.9955178160675857,
        0.9991605581781475,
        0.999899195244447,
        0.9999931550702802
      ],
      [
        0,
        0,
        0,
        0,
        0,
        0,
        2283748241799531e-28,
        4037858874020686e-28,
        2146547464825323e-28,
        5461314069809755e-27,
        4921085770524055e-27,
        4343405037091838e-27,
        3732668368707687e-27,
        3093523840190885e-27,
        2430835727329466e-27,
        1734679010007751e-27,
        974825365660928e-27,
        2797435120168326e-28,
        -5456116108943413e-27,
        -4878985199565852e-27,
        -4240448995017367e-27,
        -3559909094758253e-27,
        -2858043359288075e-27,
        -2156177623817898e-27,
        -1475637723558782e-27,
        -8371015190102975e-28,
        -2599706096327376e-28,
        -2382191739347913e-28,
        -6423305872147834e-28,
        -9400849094049688e-28,
        -1122435026096556e-27,
        -1183840321267481e-27,
        -1122435026096556e-27,
        -9400849094049688e-28,
        -6423305872147841e-28,
        -2382191739347918e-28
      ]
    ], m = A[W.SHORT_TYPE], O = A[W.SHORT_TYPE], s0 = A[W.SHORT_TYPE], K = A[W.SHORT_TYPE], t0 = [
      0,
      1,
      16,
      17,
      8,
      9,
      24,
      25,
      4,
      5,
      20,
      21,
      12,
      13,
      28,
      29,
      2,
      3,
      18,
      19,
      10,
      11,
      26,
      27,
      6,
      7,
      22,
      23,
      14,
      15,
      30,
      31
    ];
    function U(u, d, e) {
      for (var l = 10, M = d + 238 - 14 - 286, p = -15; p < 0; p++) {
        var H, B, I;
        H = D[l + -10], B = u[M + -224] * H, I = u[d + 224] * H, H = D[l + -9], B += u[M + -160] * H, I += u[d + 160] * H, H = D[l + -8], B += u[M + -96] * H, I += u[d + 96] * H, H = D[l + -7], B += u[M + -32] * H, I += u[d + 32] * H, H = D[l + -6], B += u[M + 32] * H, I += u[d + -32] * H, H = D[l + -5], B += u[M + 96] * H, I += u[d + -96] * H, H = D[l + -4], B += u[M + 160] * H, I += u[d + -160] * H, H = D[l + -3], B += u[M + 224] * H, I += u[d + -224] * H, H = D[l + -2], B += u[d + -256] * H, I -= u[M + 256] * H, H = D[l + -1], B += u[d + -192] * H, I -= u[M + 192] * H, H = D[l + 0], B += u[d + -128] * H, I -= u[M + 128] * H, H = D[l + 1], B += u[d + -64] * H, I -= u[M + 64] * H, H = D[l + 2], B += u[d + 0] * H, I -= u[M + 0] * H, H = D[l + 3], B += u[d + 64] * H, I -= u[M + -64] * H, H = D[l + 4], B += u[d + 128] * H, I -= u[M + -128] * H, H = D[l + 5], B += u[d + 192] * H, I -= u[M + -192] * H, B *= D[l + 6], H = I - B, e[30 + p * 2] = I + B, e[31 + p * 2] = D[l + 7] * H, l += 18, d--, M++;
      }
      {
        var B, I, v0, b;
        I = u[d + -16] * D[l + -10], B = u[d + -32] * D[l + -2], I += (u[d + -48] - u[d + 16]) * D[l + -9], B += u[d + -96] * D[l + -1], I += (u[d + -80] + u[d + 48]) * D[l + -8], B += u[d + -160] * D[l + 0], I += (u[d + -112] - u[d + 80]) * D[l + -7], B += u[d + -224] * D[l + 1], I += (u[d + -144] + u[d + 112]) * D[l + -6], B -= u[d + 32] * D[l + 2], I += (u[d + -176] - u[d + 144]) * D[l + -5], B -= u[d + 96] * D[l + 3], I += (u[d + -208] + u[d + 176]) * D[l + -4], B -= u[d + 160] * D[l + 4], I += (u[d + -240] - u[d + 208]) * D[l + -3], B -= u[d + 224], v0 = B - I, b = B + I, I = e[14], B = e[15] - I, e[31] = b + I, e[30] = v0 + B, e[15] = v0 - B, e[14] = b - I;
      }
      {
        var a;
        a = e[28] - e[0], e[0] += e[28], e[28] = a * D[l + -2 * 18 + 7], a = e[29] - e[1], e[1] += e[29], e[29] = a * D[l + -2 * 18 + 7], a = e[26] - e[2], e[2] += e[26], e[26] = a * D[l + -4 * 18 + 7], a = e[27] - e[3], e[3] += e[27], e[27] = a * D[l + -4 * 18 + 7], a = e[24] - e[4], e[4] += e[24], e[24] = a * D[l + -6 * 18 + 7], a = e[25] - e[5], e[5] += e[25], e[25] = a * D[l + -6 * 18 + 7], a = e[22] - e[6], e[6] += e[22], e[22] = a * X.SQRT2, a = e[23] - e[7], e[7] += e[23], e[23] = a * X.SQRT2 - e[7], e[7] -= e[6], e[22] -= e[7], e[23] -= e[22], a = e[6], e[6] = e[31] - a, e[31] = e[31] + a, a = e[7], e[7] = e[30] - a, e[30] = e[30] + a, a = e[22], e[22] = e[15] - a, e[15] = e[15] + a, a = e[23], e[23] = e[14] - a, e[14] = e[14] + a, a = e[20] - e[8], e[8] += e[20], e[20] = a * D[l + -10 * 18 + 7], a = e[21] - e[9], e[9] += e[21], e[21] = a * D[l + -10 * 18 + 7], a = e[18] - e[10], e[10] += e[18], e[18] = a * D[l + -12 * 18 + 7], a = e[19] - e[11], e[11] += e[19], e[19] = a * D[l + -12 * 18 + 7], a = e[16] - e[12], e[12] += e[16], e[16] = a * D[l + -14 * 18 + 7], a = e[17] - e[13], e[13] += e[17], e[17] = a * D[l + -14 * 18 + 7], a = -e[20] + e[24], e[20] += e[24], e[24] = a * D[l + -12 * 18 + 7], a = -e[21] + e[25], e[21] += e[25], e[25] = a * D[l + -12 * 18 + 7], a = e[4] - e[8], e[4] += e[8], e[8] = a * D[l + -12 * 18 + 7], a = e[5] - e[9], e[5] += e[9], e[9] = a * D[l + -12 * 18 + 7], a = e[0] - e[12], e[0] += e[12], e[12] = a * D[l + -4 * 18 + 7], a = e[1] - e[13], e[1] += e[13], e[13] = a * D[l + -4 * 18 + 7], a = e[16] - e[28], e[16] += e[28], e[28] = a * D[l + -4 * 18 + 7], a = -e[17] + e[29], e[17] += e[29], e[29] = a * D[l + -4 * 18 + 7], a = X.SQRT2 * (e[2] - e[10]), e[2] += e[10], e[10] = a, a = X.SQRT2 * (e[3] - e[11]), e[3] += e[11], e[11] = a, a = X.SQRT2 * (-e[18] + e[26]), e[18] += e[26], e[26] = a - e[18], a = X.SQRT2 * (-e[19] + e[27]), e[19] += e[27], e[27] = a - e[19], a = e[2], e[19] -= e[3], e[3] -= a, e[2] = e[31] - a, e[31] += a, a = e[3], e[11] -= e[19], e[18] -= a, e[3] = e[30] - a, e[30] += a, a = e[18], e[27] -= e[11], e[19] -= a, e[18] = e[15] - a, e[15] += a, a = e[19], e[10] -= a, e[19] = e[14] - a, e[14] += a, a = e[10], e[11] -= a, e[10] = e[23] - a, e[23] += a, a = e[11], e[26] -= a, e[11] = e[22] - a, e[22] += a, a = e[26], e[27] -= a, e[26] = e[7] - a, e[7] += a, a = e[27], e[27] = e[6] - a, e[6] += a, a = X.SQRT2 * (e[0] - e[4]), e[0] += e[4], e[4] = a, a = X.SQRT2 * (e[1] - e[5]), e[1] += e[5], e[5] = a, a = X.SQRT2 * (e[16] - e[20]), e[16] += e[20], e[20] = a, a = X.SQRT2 * (e[17] - e[21]), e[17] += e[21], e[21] = a, a = -X.SQRT2 * (e[8] - e[12]), e[8] += e[12], e[12] = a - e[8], a = -X.SQRT2 * (e[9] - e[13]), e[9] += e[13], e[13] = a - e[9], a = -X.SQRT2 * (e[25] - e[29]), e[25] += e[29], e[29] = a - e[25], a = -X.SQRT2 * (e[24] + e[28]), e[24] -= e[28], e[28] = a - e[24], a = e[24] - e[16], e[24] = a, a = e[20] - a, e[20] = a, a = e[28] - a, e[28] = a, a = e[25] - e[17], e[25] = a, a = e[21] - a, e[21] = a, a = e[29] - a, e[29] = a, a = e[17] - e[1], e[17] = a, a = e[9] - a, e[9] = a, a = e[25] - a, e[25] = a, a = e[5] - a, e[5] = a, a = e[21] - a, e[21] = a, a = e[13] - a, e[13] = a, a = e[29] - a, e[29] = a, a = e[1] - e[0], e[1] = a, a = e[16] - a, e[16] = a, a = e[17] - a, e[17] = a, a = e[8] - a, e[8] = a, a = e[9] - a, e[9] = a, a = e[24] - a, e[24] = a, a = e[25] - a, e[25] = a, a = e[4] - a, e[4] = a, a = e[5] - a, e[5] = a, a = e[20] - a, e[20] = a, a = e[21] - a, e[21] = a, a = e[12] - a, e[12] = a, a = e[13] - a, e[13] = a, a = e[28] - a, e[28] = a, a = e[29] - a, e[29] = a, a = e[0], e[0] += e[31], e[31] -= a, a = e[1], e[1] += e[30], e[30] -= a, a = e[16], e[16] += e[15], e[15] -= a, a = e[17], e[17] += e[14], e[14] -= a, a = e[8], e[8] += e[23], e[23] -= a, a = e[9], e[9] += e[22], e[22] -= a, a = e[24], e[24] += e[7], e[7] -= a, a = e[25], e[25] += e[6], e[6] -= a, a = e[4], e[4] += e[27], e[27] -= a, a = e[5], e[5] += e[26], e[26] -= a, a = e[20], e[20] += e[11], e[11] -= a, a = e[21], e[21] += e[10], e[10] -= a, a = e[12], e[12] += e[19], e[19] -= a, a = e[13], e[13] += e[18], e[18] -= a, a = e[28], e[28] += e[3], e[3] -= a, a = e[29], e[29] += e[2], e[2] -= a;
      }
    }
    function R(u, d) {
      for (var e = 0; e < 3; e++) {
        var l, M, p, H, B, I;
        H = u[d + 2 * 3] * A[W.SHORT_TYPE][0] - u[d + 5 * 3], l = u[d + 0 * 3] * A[W.SHORT_TYPE][2] - u[d + 3 * 3], M = H + l, p = H - l, H = u[d + 5 * 3] * A[W.SHORT_TYPE][0] + u[d + 2 * 3], l = u[d + 3 * 3] * A[W.SHORT_TYPE][2] + u[d + 0 * 3], B = H + l, I = -H + l, l = (u[d + 1 * 3] * A[W.SHORT_TYPE][1] - u[d + 4 * 3]) * 2069978111953089e-26, H = (u[d + 4 * 3] * A[W.SHORT_TYPE][1] + u[d + 1 * 3]) * 2069978111953089e-26, u[d + 3 * 0] = M * 190752519173728e-25 + l, u[d + 3 * 5] = -B * 190752519173728e-25 + H, p = p * 0.8660254037844387 * 1907525191737281e-26, B = B * 0.5 * 1907525191737281e-26 + H, u[d + 3 * 1] = p - B, u[d + 3 * 2] = p + B, M = M * 0.5 * 1907525191737281e-26 - l, I = I * 0.8660254037844387 * 1907525191737281e-26, u[d + 3 * 3] = M + I, u[d + 3 * 4] = M - I, d++;
      }
    }
    function o(u, d, e) {
      var l, M;
      {
        var p, H, B, I, v0, b, a, S;
        p = e[17] - e[9], B = e[15] - e[11], I = e[14] - e[12], v0 = e[0] + e[8], b = e[1] + e[7], a = e[2] + e[6], S = e[3] + e[5], u[d + 17] = v0 + a - S - (b - e[4]), M = (v0 + a - S) * O[12 + 7] + (b - e[4]), l = (p - B - I) * O[12 + 6], u[d + 5] = l + M, u[d + 6] = l - M, H = (e[16] - e[10]) * O[12 + 6], b = b * O[12 + 7] + e[4], l = p * O[12 + 0] + H + B * O[12 + 1] + I * O[12 + 2], M = -v0 * O[12 + 4] + b - a * O[12 + 5] + S * O[12 + 3], u[d + 1] = l + M, u[d + 2] = l - M, l = p * O[12 + 1] - H - B * O[12 + 2] + I * O[12 + 0], M = -v0 * O[12 + 5] + b - a * O[12 + 3] + S * O[12 + 4], u[d + 9] = l + M, u[d + 10] = l - M, l = p * O[12 + 2] - H + B * O[12 + 0] - I * O[12 + 1], M = v0 * O[12 + 3] - b + a * O[12 + 4] - S * O[12 + 5], u[d + 13] = l + M, u[d + 14] = l - M;
      }
      {
        var L, V, N, P, E, i, s, r;
        L = e[8] - e[0], N = e[6] - e[2], P = e[5] - e[3], E = e[17] + e[9], i = e[16] + e[10], s = e[15] + e[11], r = e[14] + e[12], u[d + 0] = E + s + r + (i + e[13]), l = (E + s + r) * O[12 + 7] - (i + e[13]), M = (L - N + P) * O[12 + 6], u[d + 11] = l + M, u[d + 12] = l - M, V = (e[7] - e[1]) * O[12 + 6], i = e[13] - i * O[12 + 7], l = E * O[12 + 3] - i + s * O[12 + 4] + r * O[12 + 5], M = L * O[12 + 2] + V + N * O[12 + 0] + P * O[12 + 1], u[d + 3] = l + M, u[d + 4] = l - M, l = -E * O[12 + 5] + i - s * O[12 + 3] - r * O[12 + 4], M = L * O[12 + 1] + V - N * O[12 + 2] - P * O[12 + 0], u[d + 7] = l + M, u[d + 8] = l - M, l = -E * O[12 + 4] + i - s * O[12 + 5] - r * O[12 + 3], M = L * O[12 + 0] - V + N * O[12 + 1] - P * O[12 + 2], u[d + 15] = l + M, u[d + 16] = l - M;
      }
    }
    this.mdct_sub48 = function(u, d, e) {
      for (var l = d, M = 286, p = 0; p < u.channels_out; p++) {
        for (var H = 0; H < u.mode_gr; H++) {
          for (var B, I = u.l3_side.tt[H][p], v0 = I.xr, b = 0, a = u.sb_sample[p][1 - H], S = 0, L = 0; L < 18 / 2; L++)
            for (U(l, M, a[S]), U(l, M + 32, a[S + 1]), S += 2, M += 64, B = 1; B < 32; B += 2)
              a[S - 1][B] *= -1;
          for (B = 0; B < 32; B++, b += 18) {
            var V = I.block_type, N = u.sb_sample[p][H], P = u.sb_sample[p][1 - H];
            if (I.mixed_block_flag != 0 && B < 2 && (V = 0), u.amp_filter[B] < 1e-12)
              z.fill(
                v0,
                b + 0,
                b + 18,
                0
              );
            else {
              if (u.amp_filter[B] < 1)
                for (var L = 0; L < 18; L++)
                  P[L][t0[B]] *= u.amp_filter[B];
              if (V == W.SHORT_TYPE) {
                for (var L = -g / 4; L < 0; L++) {
                  var E = A[W.SHORT_TYPE][L + 3];
                  v0[b + L * 3 + 9] = N[9 + L][t0[B]] * E - N[8 - L][t0[B]], v0[b + L * 3 + 18] = N[14 - L][t0[B]] * E + N[15 + L][t0[B]], v0[b + L * 3 + 10] = N[15 + L][t0[B]] * E - N[14 - L][t0[B]], v0[b + L * 3 + 19] = P[2 - L][t0[B]] * E + P[3 + L][t0[B]], v0[b + L * 3 + 11] = P[3 + L][t0[B]] * E - P[2 - L][t0[B]], v0[b + L * 3 + 20] = P[8 - L][t0[B]] * E + P[9 + L][t0[B]];
                }
                R(v0, b);
              } else {
                for (var i = u0(18), L = -f0 / 4; L < 0; L++) {
                  var s, r;
                  s = A[V][L + 27] * P[L + 9][t0[B]] + A[V][L + 36] * P[8 - L][t0[B]], r = A[V][L + 9] * N[L + 9][t0[B]] - A[V][L + 18] * N[8 - L][t0[B]], i[L + 9] = s - r * m[3 + L + 9], i[L + 18] = s * m[3 + L + 9] + r;
                }
                o(v0, b, i);
              }
            }
            if (V != W.SHORT_TYPE && B != 0)
              for (var L = 7; L >= 0; --L) {
                var n, f;
                n = v0[b + L] * s0[20 + L] + v0[b + -1 - L] * K[28 + L], f = v0[b + L] * K[28 + L] - v0[b + -1 - L] * s0[20 + L], v0[b + -1 - L] = n, v0[b + L] = f;
              }
          }
        }
        if (l = e, M = 286, u.mode_gr == 1)
          for (var Y = 0; Y < 18; Y++)
            Z.arraycopy(
              u.sb_sample[p][1][Y],
              0,
              u.sb_sample[p][0][Y],
              0,
              32
            );
      }
    };
  }
  return ce = Q, ce;
}
var Se, Ge;
function Ea() {
  if (Ge)
    return Se;
  Ge = 1;
  var w = t1(), Z = Q0, X = Z.System, z = Z.new_float, u0 = Z.new_float_n;
  function W() {
    this.l = z(w.SBMAX_l), this.s = u0([w.SBMAX_s, 3]);
    var Q = this;
    this.assign = function(D) {
      X.arraycopy(D.l, 0, Q.l, 0, w.SBMAX_l);
      for (var g = 0; g < w.SBMAX_s; g++)
        for (var f0 = 0; f0 < 3; f0++)
          Q.s[g][f0] = D.s[g][f0];
    };
  }
  return Se = W, Se;
}
var de, $e;
function Ga() {
  if ($e)
    return de;
  $e = 1;
  var w = Ea();
  function Z() {
    this.thm = new w(), this.en = new w();
  }
  return de = Z, de;
}
function R1(w) {
  var Z = w;
  this.ordinal = function() {
    return Z;
  };
}
R1.STEREO = new R1(0);
R1.JOINT_STEREO = new R1(1);
R1.DUAL_CHANNEL = new R1(2);
R1.MONO = new R1(3);
R1.NOT_SET = new R1(4);
var j1 = R1, Ae, Pe;
function t1() {
  if (Pe)
    return Ae;
  Pe = 1;
  var w = Q0, Z = w.System, X = w.VbrMode, z = w.new_array_n, u0 = w.new_float, W = w.new_float_n, Q = w.new_int, D = w.assert;
  g.ENCDELAY = 576, g.POSTDELAY = 1152, g.MDCTDELAY = 48, g.FFTOFFSET = 224 + g.MDCTDELAY, g.DECDELAY = 528, g.SBLIMIT = 32, g.CBANDS = 64, g.SBPSY_l = 21, g.SBPSY_s = 12, g.SBMAX_l = 22, g.SBMAX_s = 13, g.PSFB21 = 6, g.PSFB12 = 6, g.BLKSIZE = 1024, g.HBLKSIZE = g.BLKSIZE / 2 + 1, g.BLKSIZE_s = 256, g.HBLKSIZE_s = g.BLKSIZE_s / 2 + 1, g.NORM_TYPE = 0, g.START_TYPE = 1, g.SHORT_TYPE = 2, g.STOP_TYPE = 3, g.MPG_MD_LR_LR = 0, g.MPG_MD_LR_I = 1, g.MPG_MD_MS_LR = 2, g.MPG_MD_MS_I = 3, g.fircoef = [
    -0.0207887 * 5,
    -0.0378413 * 5,
    -0.0432472 * 5,
    -0.031183 * 5,
    779609e-23 * 5,
    0.0467745 * 5,
    0.10091 * 5,
    0.151365 * 5,
    0.187098 * 5
  ];
  function g() {
    var f0 = Da(), A = Ga(), m = j1, O = g.FFTOFFSET, s0 = g.MPG_MD_MS_LR, K = null;
    this.psy = null;
    var t0 = null, U = null, R = null;
    this.setModules = function(l, M, p, H) {
      K = l, this.psy = M, t0 = M, U = H, R = p;
    };
    var o = new f0();
    function u(l) {
      var M, p;
      if (l.ATH.useAdjust == 0) {
        l.ATH.adjust = 1;
        return;
      }
      if (p = l.loudness_sq[0][0], M = l.loudness_sq[1][0], l.channels_out == 2 ? (p += l.loudness_sq[0][1], M += l.loudness_sq[1][1]) : (p += p, M += M), l.mode_gr == 2 && (p = Math.max(p, M)), p *= 0.5, p *= l.ATH.aaSensitivityP, p > 0.03125)
        l.ATH.adjust >= 1 ? l.ATH.adjust = 1 : l.ATH.adjust < l.ATH.adjustLimit && (l.ATH.adjust = l.ATH.adjustLimit), l.ATH.adjustLimit = 1;
      else {
        var H = 31.98 * p + 625e-6;
        l.ATH.adjust >= H ? (l.ATH.adjust *= H * 0.075 + 0.925, l.ATH.adjust < H && (l.ATH.adjust = H)) : l.ATH.adjustLimit >= H ? l.ATH.adjust = H : l.ATH.adjust < l.ATH.adjustLimit && (l.ATH.adjust = l.ATH.adjustLimit), l.ATH.adjustLimit = H;
      }
    }
    function d(l) {
      var M, p;
      for (D(0 <= l.bitrate_index && l.bitrate_index < 16), D(0 <= l.mode_ext && l.mode_ext < 4), l.bitrate_stereoMode_Hist[l.bitrate_index][4]++, l.bitrate_stereoMode_Hist[15][4]++, l.channels_out == 2 && (l.bitrate_stereoMode_Hist[l.bitrate_index][l.mode_ext]++, l.bitrate_stereoMode_Hist[15][l.mode_ext]++), M = 0; M < l.mode_gr; ++M)
        for (p = 0; p < l.channels_out; ++p) {
          var H = l.l3_side.tt[M][p].block_type | 0;
          l.l3_side.tt[M][p].mixed_block_flag != 0 && (H = 4), l.bitrate_blockType_Hist[l.bitrate_index][H]++, l.bitrate_blockType_Hist[l.bitrate_index][5]++, l.bitrate_blockType_Hist[15][H]++, l.bitrate_blockType_Hist[15][5]++;
        }
    }
    function e(l, M) {
      var p = l.internal_flags, H, B;
      if (p.lame_encode_frame_init == 0) {
        var I, v0, b = u0(2014), a = u0(286 + 1152 + 576);
        for (p.lame_encode_frame_init = 1, I = 0, v0 = 0; I < 286 + 576 * (1 + p.mode_gr); ++I)
          I < 576 * p.mode_gr ? (b[I] = 0, p.channels_out == 2 && (a[I] = 0)) : (b[I] = M[0][v0], p.channels_out == 2 && (a[I] = M[1][v0]), ++v0);
        for (B = 0; B < p.mode_gr; B++)
          for (H = 0; H < p.channels_out; H++)
            p.l3_side.tt[B][H].block_type = g.SHORT_TYPE;
        o.mdct_sub48(p, b, a), D(576 >= g.FFTOFFSET), D(p.mf_size >= g.BLKSIZE + l.framesize - g.FFTOFFSET), D(p.mf_size >= 512 + l.framesize - 32);
      }
    }
    this.lame_encode_mp3_frame = function(l, M, p, H, B, I) {
      var v0, b = z([2, 2]);
      b[0][0] = new A(), b[0][1] = new A(), b[1][0] = new A(), b[1][1] = new A();
      var a = z([2, 2]);
      a[0][0] = new A(), a[0][1] = new A(), a[1][0] = new A(), a[1][1] = new A();
      var S, L = [null, null], V = l.internal_flags, N = W([2, 4]), P = [0.5, 0.5], E = [[0, 0], [0, 0]], i = [[0, 0], [0, 0]], s, r, n;
      if (L[0] = M, L[1] = p, V.lame_encode_frame_init == 0 && e(l, L), V.padding = 0, (V.slot_lag -= V.frac_SpF) < 0 && (V.slot_lag += l.out_samplerate, V.padding = 1), V.psymodel != 0) {
        var f, Y = [null, null], J = 0, T = Q(2);
        for (n = 0; n < V.mode_gr; n++) {
          for (r = 0; r < V.channels_out; r++)
            Y[r] = L[r], J = 576 + n * 576 - g.FFTOFFSET;
          if (l.VBR == X.vbr_mtrh || l.VBR == X.vbr_mt ? f = t0.L3psycho_anal_vbr(
            l,
            Y,
            J,
            n,
            b,
            a,
            E[n],
            i[n],
            N[n],
            T
          ) : f = t0.L3psycho_anal_ns(
            l,
            Y,
            J,
            n,
            b,
            a,
            E[n],
            i[n],
            N[n],
            T
          ), f != 0)
            return -4;
          for (l.mode == m.JOINT_STEREO && (P[n] = N[n][2] + N[n][3], P[n] > 0 && (P[n] = N[n][3] / P[n])), r = 0; r < V.channels_out; r++) {
            var q = V.l3_side.tt[n][r];
            q.block_type = T[r], q.mixed_block_flag = 0;
          }
        }
      } else
        for (n = 0; n < V.mode_gr; n++)
          for (r = 0; r < V.channels_out; r++)
            V.l3_side.tt[n][r].block_type = g.NORM_TYPE, V.l3_side.tt[n][r].mixed_block_flag = 0, i[n][r] = E[n][r] = 700;
      if (u(V), o.mdct_sub48(V, L[0], L[1]), V.mode_ext = g.MPG_MD_LR_LR, l.force_ms)
        V.mode_ext = g.MPG_MD_MS_LR;
      else if (l.mode == m.JOINT_STEREO) {
        var i0 = 0, h0 = 0;
        for (n = 0; n < V.mode_gr; n++)
          for (r = 0; r < V.channels_out; r++)
            i0 += i[n][r], h0 += E[n][r];
        if (i0 <= 1 * h0) {
          var d0 = V.l3_side.tt[0], M0 = V.l3_side.tt[V.mode_gr - 1];
          d0[0].block_type == d0[1].block_type && M0[0].block_type == M0[1].block_type && (V.mode_ext = g.MPG_MD_MS_LR);
        }
      }
      if (V.mode_ext == s0 ? (S = a, s = i) : (S = b, s = E), l.analysis && V.pinfo != null)
        for (n = 0; n < V.mode_gr; n++)
          for (r = 0; r < V.channels_out; r++)
            V.pinfo.ms_ratio[n] = V.ms_ratio[n], V.pinfo.ms_ener_ratio[n] = P[n], V.pinfo.blocktype[n][r] = V.l3_side.tt[n][r].block_type, V.pinfo.pe[n][r] = s[n][r], Z.arraycopy(
              V.l3_side.tt[n][r].xr,
              0,
              V.pinfo.xr[n][r],
              0,
              576
            ), V.mode_ext == s0 && (V.pinfo.ers[n][r] = V.pinfo.ers[n][r + 2], Z.arraycopy(
              V.pinfo.energy[n][r + 2],
              0,
              V.pinfo.energy[n][r],
              0,
              V.pinfo.energy[n][r].length
            ));
      if (l.VBR == X.vbr_off || l.VBR == X.vbr_abr) {
        var R0, A0;
        for (R0 = 0; R0 < 18; R0++)
          V.nsPsy.pefirbuf[R0] = V.nsPsy.pefirbuf[R0 + 1];
        for (A0 = 0, n = 0; n < V.mode_gr; n++)
          for (r = 0; r < V.channels_out; r++)
            A0 += s[n][r];
        for (V.nsPsy.pefirbuf[18] = A0, A0 = V.nsPsy.pefirbuf[9], R0 = 0; R0 < 9; R0++)
          A0 += (V.nsPsy.pefirbuf[R0] + V.nsPsy.pefirbuf[18 - R0]) * g.fircoef[R0];
        for (A0 = 670 * 5 * V.mode_gr * V.channels_out / A0, n = 0; n < V.mode_gr; n++)
          for (r = 0; r < V.channels_out; r++)
            s[n][r] *= A0;
      }
      if (V.iteration_loop.iteration_loop(l, s, P, S), K.format_bitstream(l), v0 = K.copy_buffer(V, H, B, I, 1), l.bWriteVbrTag && U.addVbrFrame(l), l.analysis && V.pinfo != null) {
        for (r = 0; r < V.channels_out; r++) {
          var w0;
          for (w0 = 0; w0 < O; w0++)
            V.pinfo.pcmdata[r][w0] = V.pinfo.pcmdata[r][w0 + l.framesize];
          for (w0 = O; w0 < 1600; w0++)
            V.pinfo.pcmdata[r][w0] = L[r][w0 - O];
        }
        R.set_frame_pinfo(l, S);
      }
      return d(V), v0;
    };
  }
  return Ae = g, Ae;
}
var Ba = Q0, Ze = Ba.Util, Ke = Ba.new_float, J0 = t1();
function $a() {
  var w = Ke(J0.BLKSIZE), Z = Ke(J0.BLKSIZE_s / 2), X = [
    0.9238795325112867,
    0.3826834323650898,
    0.9951847266721969,
    0.0980171403295606,
    0.9996988186962042,
    0.02454122852291229,
    0.9999811752826011,
    0.006135884649154475
  ];
  function z(W, Q, D) {
    var g = 0, f0, A, m;
    D <<= 1;
    var O = Q + D;
    f0 = 4;
    do {
      var s0, K, t0, U, R, o, u;
      u = f0 >> 1, U = f0, R = f0 << 1, o = R + U, f0 = R << 1, A = Q, m = A + u;
      do {
        var d, e, l, M;
        e = W[A + 0] - W[A + U], d = W[A + 0] + W[A + U], M = W[A + R] - W[A + o], l = W[A + R] + W[A + o], W[A + R] = d - l, W[A + 0] = d + l, W[A + o] = e - M, W[A + U] = e + M, e = W[m + 0] - W[m + U], d = W[m + 0] + W[m + U], M = Ze.SQRT2 * W[m + o], l = Ze.SQRT2 * W[m + R], W[m + R] = d - l, W[m + 0] = d + l, W[m + o] = e - M, W[m + U] = e + M, m += f0, A += f0;
      } while (A < O);
      for (K = X[g + 0], s0 = X[g + 1], t0 = 1; t0 < u; t0++) {
        var p, H;
        p = 1 - 2 * s0 * s0, H = 2 * s0 * K, A = Q + t0, m = Q + U - t0;
        do {
          var B, I, v0, d, e, b, l, a, M, S;
          I = H * W[A + U] - p * W[m + U], B = p * W[A + U] + H * W[m + U], e = W[A + 0] - B, d = W[A + 0] + B, b = W[m + 0] - I, v0 = W[m + 0] + I, I = H * W[A + o] - p * W[m + o], B = p * W[A + o] + H * W[m + o], M = W[A + R] - B, l = W[A + R] + B, S = W[m + R] - I, a = W[m + R] + I, I = s0 * l - K * S, B = K * l + s0 * S, W[A + R] = d - B, W[A + 0] = d + B, W[m + o] = b - I, W[m + U] = b + I, I = K * a - s0 * M, B = s0 * a + K * M, W[m + R] = v0 - B, W[m + 0] = v0 + B, W[A + o] = e - I, W[A + U] = e + I, m += f0, A += f0;
        } while (A < O);
        p = K, K = p * X[g + 0] - s0 * X[g + 1], s0 = p * X[g + 1] + s0 * X[g + 0];
      }
      g += 2;
    } while (f0 < D);
  }
  var u0 = [
    0,
    128,
    64,
    192,
    32,
    160,
    96,
    224,
    16,
    144,
    80,
    208,
    48,
    176,
    112,
    240,
    8,
    136,
    72,
    200,
    40,
    168,
    104,
    232,
    24,
    152,
    88,
    216,
    56,
    184,
    120,
    248,
    4,
    132,
    68,
    196,
    36,
    164,
    100,
    228,
    20,
    148,
    84,
    212,
    52,
    180,
    116,
    244,
    12,
    140,
    76,
    204,
    44,
    172,
    108,
    236,
    28,
    156,
    92,
    220,
    60,
    188,
    124,
    252,
    2,
    130,
    66,
    194,
    34,
    162,
    98,
    226,
    18,
    146,
    82,
    210,
    50,
    178,
    114,
    242,
    10,
    138,
    74,
    202,
    42,
    170,
    106,
    234,
    26,
    154,
    90,
    218,
    58,
    186,
    122,
    250,
    6,
    134,
    70,
    198,
    38,
    166,
    102,
    230,
    22,
    150,
    86,
    214,
    54,
    182,
    118,
    246,
    14,
    142,
    78,
    206,
    46,
    174,
    110,
    238,
    30,
    158,
    94,
    222,
    62,
    190,
    126,
    254
  ];
  this.fft_short = function(W, Q, D, g, f0) {
    for (var A = 0; A < 3; A++) {
      var m = J0.BLKSIZE_s / 2, O = 65535 & 576 / 3 * (A + 1), s0 = J0.BLKSIZE_s / 8 - 1;
      do {
        var K, t0, U, R, o, u = u0[s0 << 2] & 255;
        K = Z[u] * g[D][f0 + u + O], o = Z[127 - u] * g[D][f0 + u + O + 128], t0 = K - o, K = K + o, U = Z[u + 64] * g[D][f0 + u + O + 64], o = Z[63 - u] * g[D][f0 + u + O + 192], R = U - o, U = U + o, m -= 4, Q[A][m + 0] = K + U, Q[A][m + 2] = K - U, Q[A][m + 1] = t0 + R, Q[A][m + 3] = t0 - R, K = Z[u + 1] * g[D][f0 + u + O + 1], o = Z[126 - u] * g[D][f0 + u + O + 129], t0 = K - o, K = K + o, U = Z[u + 65] * g[D][f0 + u + O + 65], o = Z[62 - u] * g[D][f0 + u + O + 193], R = U - o, U = U + o, Q[A][m + J0.BLKSIZE_s / 2 + 0] = K + U, Q[A][m + J0.BLKSIZE_s / 2 + 2] = K - U, Q[A][m + J0.BLKSIZE_s / 2 + 1] = t0 + R, Q[A][m + J0.BLKSIZE_s / 2 + 3] = t0 - R;
      } while (--s0 >= 0);
      z(Q[A], m, J0.BLKSIZE_s / 2);
    }
  }, this.fft_long = function(W, Q, D, g, f0) {
    var A = J0.BLKSIZE / 8 - 1, m = J0.BLKSIZE / 2;
    do {
      var O, s0, K, t0, U, R = u0[A] & 255;
      O = w[R] * g[D][f0 + R], U = w[R + 512] * g[D][f0 + R + 512], s0 = O - U, O = O + U, K = w[R + 256] * g[D][f0 + R + 256], U = w[R + 768] * g[D][f0 + R + 768], t0 = K - U, K = K + U, m -= 4, Q[m + 0] = O + K, Q[m + 2] = O - K, Q[m + 1] = s0 + t0, Q[m + 3] = s0 - t0, O = w[R + 1] * g[D][f0 + R + 1], U = w[R + 513] * g[D][f0 + R + 513], s0 = O - U, O = O + U, K = w[R + 257] * g[D][f0 + R + 257], U = w[R + 769] * g[D][f0 + R + 769], t0 = K - U, K = K + U, Q[m + J0.BLKSIZE / 2 + 0] = O + K, Q[m + J0.BLKSIZE / 2 + 2] = O - K, Q[m + J0.BLKSIZE / 2 + 1] = s0 + t0, Q[m + J0.BLKSIZE / 2 + 3] = s0 - t0;
    } while (--A >= 0);
    z(Q, m, J0.BLKSIZE / 2);
  }, this.init_fft = function(W) {
    for (var Q = 0; Q < J0.BLKSIZE; Q++)
      w[Q] = 0.42 - 0.5 * Math.cos(2 * Math.PI * (Q + 0.5) / J0.BLKSIZE) + 0.08 * Math.cos(4 * Math.PI * (Q + 0.5) / J0.BLKSIZE);
    for (var Q = 0; Q < J0.BLKSIZE_s / 2; Q++)
      Z[Q] = 0.5 * (1 - Math.cos(2 * Math.PI * (Q + 0.5) / J0.BLKSIZE_s));
  };
}
var Pa = $a, T1 = Q0, C1 = T1.VbrMode, Ue = T1.Float, F1 = T1.ShortBlock, n1 = T1.Util, Za = T1.Arrays, g0 = T1.new_float, m1 = T1.new_float_n, L1 = T1.new_int, C0 = T1.assert, Ka = Pa, r0 = t1();
function Ua() {
  var w = j1, Z = new Ka(), X = 2.302585092994046, z = 2, u0 = 16, W = 2, Q = 16, D = 0.34, g = 1 / (14752 * 14752) / (r0.BLKSIZE / 2), f0 = 0.01, A = 0.8, m = 0.6, O = 0.3, s0 = 3.5, K = 21, t0 = 0.2302585093;
  function U(v) {
    return v;
  }
  function R(v, h) {
    for (var x = 0, y = 0; y < r0.BLKSIZE / 2; ++y)
      x += v[y] * h.ATH.eql_w[y];
    return x *= g, x;
  }
  function o(v, h, x, y, k, c, C, G, F, e0, $) {
    var a0 = v.internal_flags;
    if (F < 2)
      Z.fft_long(a0, y[k], F, e0, $), Z.fft_short(a0, c[C], F, e0, $);
    else if (F == 2) {
      for (var m0 = r0.BLKSIZE - 1; m0 >= 0; --m0) {
        var N0 = y[k + 0][m0], n0 = y[k + 1][m0];
        y[k + 0][m0] = (N0 + n0) * n1.SQRT2 * 0.5, y[k + 1][m0] = (N0 - n0) * n1.SQRT2 * 0.5;
      }
      for (var L0 = 2; L0 >= 0; --L0)
        for (var m0 = r0.BLKSIZE_s - 1; m0 >= 0; --m0) {
          var N0 = c[C + 0][L0][m0], n0 = c[C + 1][L0][m0];
          c[C + 0][L0][m0] = (N0 + n0) * n1.SQRT2 * 0.5, c[C + 1][L0][m0] = (N0 - n0) * n1.SQRT2 * 0.5;
        }
    }
    h[0] = y[k + 0][0], h[0] *= h[0];
    for (var m0 = r0.BLKSIZE / 2 - 1; m0 >= 0; --m0) {
      var j = y[k + 0][r0.BLKSIZE / 2 - m0], x0 = y[k + 0][r0.BLKSIZE / 2 + m0];
      h[r0.BLKSIZE / 2 - m0] = (j * j + x0 * x0) * 0.5;
    }
    for (var L0 = 2; L0 >= 0; --L0) {
      x[L0][0] = c[C + 0][L0][0], x[L0][0] *= x[L0][0];
      for (var m0 = r0.BLKSIZE_s / 2 - 1; m0 >= 0; --m0) {
        var j = c[C + 0][L0][r0.BLKSIZE_s / 2 - m0], x0 = c[C + 0][L0][r0.BLKSIZE_s / 2 + m0];
        x[L0][r0.BLKSIZE_s / 2 - m0] = (j * j + x0 * x0) * 0.5;
      }
    }
    {
      for (var k0 = 0, m0 = 11; m0 < r0.HBLKSIZE; m0++)
        k0 += h[m0];
      a0.tot_ener[F] = k0;
    }
    if (v.analysis) {
      for (var m0 = 0; m0 < r0.HBLKSIZE; m0++)
        a0.pinfo.energy[G][F][m0] = a0.pinfo.energy_save[F][m0], a0.pinfo.energy_save[F][m0] = h[m0];
      a0.pinfo.pe[G][F] = a0.pe[F];
    }
    v.athaa_loudapprox == 2 && F < 2 && (a0.loudness_sq[G][F] = a0.loudness_sq_save[F], a0.loudness_sq_save[F] = R(h, a0));
  }
  var u = 8, d = 23, e = 15, l, M, p, H = [
    1,
    0.79433,
    0.63096,
    0.63096,
    0.63096,
    0.63096,
    0.63096,
    0.25119,
    0.11749
  ];
  function B() {
    l = Math.pow(10, (u + 1) / 16), M = Math.pow(10, (d + 1) / 16), p = Math.pow(10, e / 10);
  }
  var I = [
    3.3246 * 3.3246,
    3.23837 * 3.23837,
    3.15437 * 3.15437,
    3.00412 * 3.00412,
    2.86103 * 2.86103,
    2.65407 * 2.65407,
    2.46209 * 2.46209,
    2.284 * 2.284,
    2.11879 * 2.11879,
    1.96552 * 1.96552,
    1.82335 * 1.82335,
    1.69146 * 1.69146,
    1.56911 * 1.56911,
    1.46658 * 1.46658,
    1.37074 * 1.37074,
    1.31036 * 1.31036,
    1.25264 * 1.25264,
    1.20648 * 1.20648,
    1.16203 * 1.16203,
    1.12765 * 1.12765,
    1.09428 * 1.09428,
    1.0659 * 1.0659,
    1.03826 * 1.03826,
    1.01895 * 1.01895,
    1
  ], v0 = [
    1.33352 * 1.33352,
    1.35879 * 1.35879,
    1.38454 * 1.38454,
    1.39497 * 1.39497,
    1.40548 * 1.40548,
    1.3537 * 1.3537,
    1.30382 * 1.30382,
    1.22321 * 1.22321,
    1.14758 * 1.14758,
    1
  ], b = [
    2.35364 * 2.35364,
    2.29259 * 2.29259,
    2.23313 * 2.23313,
    2.12675 * 2.12675,
    2.02545 * 2.02545,
    1.87894 * 1.87894,
    1.74303 * 1.74303,
    1.61695 * 1.61695,
    1.49999 * 1.49999,
    1.39148 * 1.39148,
    1.29083 * 1.29083,
    1.19746 * 1.19746,
    1.11084 * 1.11084,
    1.03826 * 1.03826
  ];
  function a(v, h, x, y, k, c) {
    var C;
    if (h > v)
      if (h < v * M)
        C = h / v;
      else
        return v + h;
    else {
      if (v >= h * M)
        return v + h;
      C = v / h;
    }
    if (v += h, y + 3 <= 3 + 3) {
      if (C >= l)
        return v;
      var G = 0 | n1.FAST_LOG10_X(C, 16);
      return v * v0[G];
    }
    var G = 0 | n1.FAST_LOG10_X(C, 16);
    if (c != 0 ? h = k.ATH.cb_s[x] * k.ATH.adjust : h = k.ATH.cb_l[x] * k.ATH.adjust, v < p * h) {
      if (v > h) {
        var F, e0;
        return F = 1, G <= 13 && (F = b[G]), e0 = n1.FAST_LOG10_X(v / h, 10 / 15), v * ((I[G] - F) * e0 + F);
      }
      return G > 13 ? v : v * b[G];
    }
    return v * I[G];
  }
  var S = [
    1.33352 * 1.33352,
    1.35879 * 1.35879,
    1.38454 * 1.38454,
    1.39497 * 1.39497,
    1.40548 * 1.40548,
    1.3537 * 1.3537,
    1.30382 * 1.30382,
    1.22321 * 1.22321,
    1.14758 * 1.14758,
    1
  ];
  function L(v, h, x) {
    var y;
    if (v < 0 && (v = 0), h < 0 && (h = 0), v <= 0)
      return h;
    if (h <= 0)
      return v;
    if (h > v ? y = h / v : y = v / h, -2 <= x && x <= 2) {
      if (y >= l)
        return v + h;
      var k = 0 | n1.FAST_LOG10_X(y, 16);
      return (v + h) * S[k];
    }
    return y < M ? v + h : (v < h && (v = h), v);
  }
  function V(v, h) {
    var x = v.internal_flags;
    if (x.channels_out > 1) {
      for (var y = 0; y < r0.SBMAX_l; y++) {
        var k = x.thm[0].l[y], c = x.thm[1].l[y];
        x.thm[0].l[y] += c * h, x.thm[1].l[y] += k * h;
      }
      for (var y = 0; y < r0.SBMAX_s; y++)
        for (var C = 0; C < 3; C++) {
          var k = x.thm[0].s[y][C], c = x.thm[1].s[y][C];
          x.thm[0].s[y][C] += c * h, x.thm[1].s[y][C] += k * h;
        }
    }
  }
  function N(v) {
    for (var h = 0; h < r0.SBMAX_l; h++)
      if (!(v.thm[0].l[h] > 1.58 * v.thm[1].l[h] || v.thm[1].l[h] > 1.58 * v.thm[0].l[h])) {
        var x = v.mld_l[h] * v.en[3].l[h], y = Math.max(
          v.thm[2].l[h],
          Math.min(v.thm[3].l[h], x)
        );
        x = v.mld_l[h] * v.en[2].l[h];
        var k = Math.max(
          v.thm[3].l[h],
          Math.min(v.thm[2].l[h], x)
        );
        v.thm[2].l[h] = y, v.thm[3].l[h] = k;
      }
    for (var h = 0; h < r0.SBMAX_s; h++)
      for (var c = 0; c < 3; c++)
        if (!(v.thm[0].s[h][c] > 1.58 * v.thm[1].s[h][c] || v.thm[1].s[h][c] > 1.58 * v.thm[0].s[h][c])) {
          var x = v.mld_s[h] * v.en[3].s[h][c], y = Math.max(
            v.thm[2].s[h][c],
            Math.min(v.thm[3].s[h][c], x)
          );
          x = v.mld_s[h] * v.en[2].s[h][c];
          var k = Math.max(
            v.thm[3].s[h][c],
            Math.min(v.thm[2].s[h][c], x)
          );
          v.thm[2].s[h][c] = y, v.thm[3].s[h][c] = k;
        }
  }
  function P(v, h, x) {
    var y = h, k = Math.pow(10, x);
    h *= 2, y *= 2;
    for (var c = 0; c < r0.SBMAX_l; c++) {
      var C, G, F, e0;
      if (e0 = v.ATH.cb_l[v.bm_l[c]] * k, C = Math.min(
        Math.max(v.thm[0].l[c], e0),
        Math.max(v.thm[1].l[c], e0)
      ), G = Math.max(v.thm[2].l[c], e0), F = Math.max(v.thm[3].l[c], e0), C * h < G + F) {
        var $ = C * y / (G + F);
        G *= $, F *= $;
      }
      v.thm[2].l[c] = Math.min(G, v.thm[2].l[c]), v.thm[3].l[c] = Math.min(F, v.thm[3].l[c]);
    }
    k *= r0.BLKSIZE_s / r0.BLKSIZE;
    for (var c = 0; c < r0.SBMAX_s; c++)
      for (var a0 = 0; a0 < 3; a0++) {
        var C, G, F, e0;
        if (e0 = v.ATH.cb_s[v.bm_s[c]] * k, C = Math.min(
          Math.max(v.thm[0].s[c][a0], e0),
          Math.max(v.thm[1].s[c][a0], e0)
        ), G = Math.max(v.thm[2].s[c][a0], e0), F = Math.max(v.thm[3].s[c][a0], e0), C * h < G + F) {
          var $ = C * h / (G + F);
          G *= $, F *= $;
        }
        v.thm[2].s[c][a0] = Math.min(
          v.thm[2].s[c][a0],
          G
        ), v.thm[3].s[c][a0] = Math.min(
          v.thm[3].s[c][a0],
          F
        );
      }
  }
  function E(v, h, x, y, k) {
    var c, C, G = 0, F = 0;
    for (c = C = 0; c < r0.SBMAX_s; ++C, ++c) {
      for (var e0 = v.bo_s[c], $ = v.npart_s, a0 = e0 < $ ? e0 : $; C < a0; )
        C0(h[C] >= 0), C0(x[C] >= 0), G += h[C], F += x[C], C++;
      if (v.en[y].s[c][k] = G, v.thm[y].s[c][k] = F, C >= $) {
        ++c;
        break;
      }
      C0(h[C] >= 0), C0(x[C] >= 0);
      {
        var m0 = v.PSY.bo_s_weight[c], N0 = 1 - m0;
        G = m0 * h[C], F = m0 * x[C], v.en[y].s[c][k] += G, v.thm[y].s[c][k] += F, G = N0 * h[C], F = N0 * x[C];
      }
    }
    for (; c < r0.SBMAX_s; ++c)
      v.en[y].s[c][k] = 0, v.thm[y].s[c][k] = 0;
  }
  function i(v, h, x, y) {
    var k, c, C = 0, G = 0;
    for (k = c = 0; k < r0.SBMAX_l; ++c, ++k) {
      for (var F = v.bo_l[k], e0 = v.npart_l, $ = F < e0 ? F : e0; c < $; )
        C0(h[c] >= 0), C0(x[c] >= 0), C += h[c], G += x[c], c++;
      if (v.en[y].l[k] = C, v.thm[y].l[k] = G, c >= e0) {
        ++k;
        break;
      }
      C0(h[c] >= 0), C0(x[c] >= 0);
      {
        var a0 = v.PSY.bo_l_weight[k], m0 = 1 - a0;
        C = a0 * h[c], G = a0 * x[c], v.en[y].l[k] += C, v.thm[y].l[k] += G, C = m0 * h[c], G = m0 * x[c];
      }
    }
    for (; k < r0.SBMAX_l; ++k)
      v.en[y].l[k] = 0, v.thm[y].l[k] = 0;
  }
  function s(v, h, x, y, k, c) {
    var C = v.internal_flags, G, F;
    for (F = G = 0; F < C.npart_s; ++F) {
      for (var e0 = 0, $ = C.numlines_s[F], a0 = 0; a0 < $; ++a0, ++G) {
        var m0 = h[c][G];
        e0 += m0;
      }
      x[F] = e0;
    }
    for (C0(F == C.npart_s), G = F = 0; F < C.npart_s; F++) {
      var N0 = C.s3ind_s[F][0], n0 = C.s3_ss[G++] * x[N0];
      for (++N0; N0 <= C.s3ind_s[F][1]; )
        n0 += C.s3_ss[G] * x[N0], ++G, ++N0;
      {
        var L0 = W * C.nb_s1[k][F];
        y[F] = Math.min(n0, L0);
      }
      if (C.blocktype_old[k & 1] == r0.SHORT_TYPE) {
        var L0 = Q * C.nb_s2[k][F], j = y[F];
        y[F] = Math.min(L0, j);
      }
      C.nb_s2[k][F] = C.nb_s1[k][F], C.nb_s1[k][F] = n0, C0(y[F] >= 0);
    }
    for (; F <= r0.CBANDS; ++F)
      x[F] = 0, y[F] = 0;
  }
  function r(v, h, x, y) {
    var k = v.internal_flags;
    v.short_blocks == F1.short_block_coupled && !(h[0] != 0 && h[1] != 0) && (h[0] = h[1] = 0);
    for (var c = 0; c < k.channels_out; c++)
      y[c] = r0.NORM_TYPE, v.short_blocks == F1.short_block_dispensed && (h[c] = 1), v.short_blocks == F1.short_block_forced && (h[c] = 0), h[c] != 0 ? (C0(k.blocktype_old[c] != r0.START_TYPE), k.blocktype_old[c] == r0.SHORT_TYPE && (y[c] = r0.STOP_TYPE)) : (y[c] = r0.SHORT_TYPE, k.blocktype_old[c] == r0.NORM_TYPE && (k.blocktype_old[c] = r0.START_TYPE), k.blocktype_old[c] == r0.STOP_TYPE && (k.blocktype_old[c] = r0.SHORT_TYPE)), x[c] = k.blocktype_old[c], k.blocktype_old[c] = y[c];
  }
  function n(v, h, x) {
    return x >= 1 ? v : x <= 0 ? h : h > 0 ? Math.pow(v / h, x) * h : 0;
  }
  var f = [
    11.8,
    13.6,
    17.2,
    32,
    46.5,
    51.3,
    57.5,
    67.1,
    71.5,
    84.6,
    97.6,
    130
    /* 255.8 */
  ];
  function Y(v, h) {
    for (var x = 309.07, y = 0; y < r0.SBMAX_s - 1; y++)
      for (var k = 0; k < 3; k++) {
        var c = v.thm.s[y][k];
        if (c > 0) {
          var C = c * h, G = v.en.s[y][k];
          G > C && (G > C * 1e10 ? x += f[y] * (10 * X) : x += f[y] * n1.FAST_LOG10(G / C));
        }
      }
    return x;
  }
  var J = [
    6.8,
    5.8,
    5.8,
    6.4,
    6.5,
    9.9,
    12.1,
    14.4,
    15,
    18.9,
    21.6,
    26.9,
    34.2,
    40.2,
    46.8,
    56.5,
    60.7,
    73.9,
    85.7,
    93.4,
    126.1
    /* 241.3 */
  ];
  function T(v, h) {
    for (var x = 281.0575, y = 0; y < r0.SBMAX_l - 1; y++) {
      var k = v.thm.l[y];
      if (k > 0) {
        var c = k * h, C = v.en.l[y];
        C > c && (C > c * 1e10 ? x += J[y] * (10 * X) : x += J[y] * n1.FAST_LOG10(C / c));
      }
    }
    return x;
  }
  function q(v, h, x, y, k) {
    var c, C;
    for (c = C = 0; c < v.npart_l; ++c) {
      var G = 0, F = 0, e0;
      for (e0 = 0; e0 < v.numlines_l[c]; ++e0, ++C) {
        var $ = h[C];
        G += $, F < $ && (F = $);
      }
      x[c] = G, y[c] = F, k[c] = G * v.rnumlines_l[c], C0(v.rnumlines_l[c] >= 0), C0(x[c] >= 0), C0(y[c] >= 0), C0(k[c] >= 0);
    }
  }
  function i0(v, h, x, y) {
    var k = H.length - 1, c = 0, C = x[c] + x[c + 1];
    if (C > 0) {
      var G = h[c];
      G < h[c + 1] && (G = h[c + 1]), C0(v.numlines_l[c] + v.numlines_l[c + 1] - 1 > 0), C = 20 * (G * 2 - C) / (C * (v.numlines_l[c] + v.numlines_l[c + 1] - 1));
      var F = 0 | C;
      F > k && (F = k), y[c] = F;
    } else
      y[c] = 0;
    for (c = 1; c < v.npart_l - 1; c++)
      if (C = x[c - 1] + x[c] + x[c + 1], C > 0) {
        var G = h[c - 1];
        G < h[c] && (G = h[c]), G < h[c + 1] && (G = h[c + 1]), C0(v.numlines_l[c - 1] + v.numlines_l[c] + v.numlines_l[c + 1] - 1 > 0), C = 20 * (G * 3 - C) / (C * (v.numlines_l[c - 1] + v.numlines_l[c] + v.numlines_l[c + 1] - 1));
        var F = 0 | C;
        F > k && (F = k), y[c] = F;
      } else
        y[c] = 0;
    if (C0(c == v.npart_l - 1), C = x[c - 1] + x[c], C > 0) {
      var G = h[c - 1];
      G < h[c] && (G = h[c]), C0(v.numlines_l[c - 1] + v.numlines_l[c] - 1 > 0), C = 20 * (G * 2 - C) / (C * (v.numlines_l[c - 1] + v.numlines_l[c] - 1));
      var F = 0 | C;
      F > k && (F = k), y[c] = F;
    } else
      y[c] = 0;
    C0(c == v.npart_l - 1);
  }
  var h0 = [
    -865163e-23 * 2,
    -851586e-8 * 2,
    -674764e-23 * 2,
    0.0209036 * 2,
    -336639e-22 * 2,
    -0.0438162 * 2,
    -154175e-22 * 2,
    0.0931738 * 2,
    -552212e-22 * 2,
    -0.313819 * 2
  ];
  this.L3psycho_anal_ns = function(v, h, x, y, k, c, C, G, F, e0) {
    var $ = v.internal_flags, a0 = m1([2, r0.BLKSIZE]), m0 = m1([2, 3, r0.BLKSIZE_s]), N0 = g0(r0.CBANDS + 1), n0 = g0(r0.CBANDS + 1), L0 = g0(r0.CBANDS + 2), j = L1(2), x0 = L1(2), k0, _0, B0, l0, p0, P0, c0, O0, X0 = m1([2, 576]), Z0, v1 = L1(r0.CBANDS + 2), z0 = L1(r0.CBANDS + 2);
    for (Za.fill(z0, 0), k0 = $.channels_out, v.mode == w.JOINT_STEREO && (k0 = 4), v.VBR == C1.vbr_off ? Z0 = $.ResvMax == 0 ? 0 : $.ResvSize / $.ResvMax * 0.5 : v.VBR == C1.vbr_rh || v.VBR == C1.vbr_mtrh || v.VBR == C1.vbr_mt ? Z0 = 0.6 : Z0 = 1, _0 = 0; _0 < $.channels_out; _0++) {
      var K0 = h[_0], s1 = x + 576 - 350 - K + 192;
      for (l0 = 0; l0 < 576; l0++) {
        var o1, h1;
        for (o1 = K0[s1 + l0 + 10], h1 = 0, p0 = 0; p0 < (K - 1) / 2 - 1; p0 += 2)
          o1 += h0[p0] * (K0[s1 + l0 + p0] + K0[s1 + l0 + K - p0]), h1 += h0[p0 + 1] * (K0[s1 + l0 + p0 + 1] + K0[s1 + l0 + K - p0 - 1]);
        X0[_0][l0] = o1 + h1;
      }
      k[y][_0].en.assign($.en[_0]), k[y][_0].thm.assign($.thm[_0]), k0 > 2 && (c[y][_0].en.assign($.en[_0 + 2]), c[y][_0].thm.assign($.thm[_0 + 2]));
    }
    for (_0 = 0; _0 < k0; _0++) {
      var c1, S1, r1 = g0(12), x1 = [0, 0, 0, 0], O1 = g0(12), le = 1, Ce, Fe = g0(r0.CBANDS), ke = g0(r0.CBANDS), U0 = [0, 0, 0, 0], Xe = g0(r0.HBLKSIZE), Ye = m1([3, r0.HBLKSIZE_s]);
      for (C0($.npart_s <= r0.CBANDS), C0($.npart_l <= r0.CBANDS), l0 = 0; l0 < 3; l0++)
        r1[l0] = $.nsPsy.last_en_subshort[_0][l0 + 6], C0($.nsPsy.last_en_subshort[_0][l0 + 4] > 0), O1[l0] = r1[l0] / $.nsPsy.last_en_subshort[_0][l0 + 4], x1[0] += r1[l0];
      if (_0 == 2)
        for (l0 = 0; l0 < 576; l0++) {
          var ve, oe;
          ve = X0[0][l0], oe = X0[1][l0], X0[0][l0] = ve + oe, X0[1][l0] = ve - oe;
        }
      {
        var qe = X0[_0 & 1], G1 = 0;
        for (l0 = 0; l0 < 9; l0++) {
          for (var ka = G1 + 64, a1 = 1; G1 < ka; G1++)
            a1 < Math.abs(qe[G1]) && (a1 = Math.abs(qe[G1]));
          $.nsPsy.last_en_subshort[_0][l0] = r1[l0 + 3] = a1, x1[1 + l0 / 3] += a1, a1 > r1[l0 + 3 - 2] ? (C0(r1[l0 + 3 - 2] > 0), a1 = a1 / r1[l0 + 3 - 2]) : r1[l0 + 3 - 2] > a1 * 10 ? a1 = r1[l0 + 3 - 2] / (a1 * 10) : a1 = 0, O1[l0 + 3] = a1;
        }
      }
      if (v.analysis) {
        var he = O1[0];
        for (l0 = 1; l0 < 12; l0++)
          he < O1[l0] && (he = O1[l0]);
        $.pinfo.ers[y][_0] = $.pinfo.ers_save[_0], $.pinfo.ers_save[_0] = he;
      }
      for (Ce = _0 == 3 ? $.nsPsy.attackthre_s : $.nsPsy.attackthre, l0 = 0; l0 < 12; l0++)
        U0[l0 / 3] == 0 && O1[l0] > Ce && (U0[l0 / 3] = l0 % 3 + 1);
      for (l0 = 1; l0 < 4; l0++) {
        var ue;
        x1[l0 - 1] > x1[l0] ? (C0(x1[l0] > 0), ue = x1[l0 - 1] / x1[l0]) : (C0(x1[l0 - 1] > 0), ue = x1[l0] / x1[l0 - 1]), ue < 1.7 && (U0[l0] = 0, l0 == 1 && (U0[0] = 0));
      }
      for (U0[0] != 0 && $.nsPsy.lastAttacks[_0] != 0 && (U0[0] = 0), ($.nsPsy.lastAttacks[_0] == 3 || U0[0] + U0[1] + U0[2] + U0[3] != 0) && (le = 0, U0[1] != 0 && U0[0] != 0 && (U0[1] = 0), U0[2] != 0 && U0[1] != 0 && (U0[2] = 0), U0[3] != 0 && U0[2] != 0 && (U0[3] = 0)), _0 < 2 ? x0[_0] = le : le == 0 && (x0[0] = x0[1] = 0), F[_0] = $.tot_ener[_0], S1 = m0, c1 = a0, o(
        v,
        Xe,
        Ye,
        c1,
        _0 & 1,
        S1,
        _0 & 1,
        y,
        _0,
        h,
        x
      ), q($, Xe, N0, Fe, ke), i0($, Fe, ke, v1), O0 = 0; O0 < 3; O0++) {
        var fe, i1;
        for (s(v, Ye, n0, L0, _0, O0), E($, n0, L0, _0, O0), c0 = 0; c0 < r0.SBMAX_s; c0++) {
          if (i1 = $.thm[_0].s[c0][O0], i1 *= A, U0[O0] >= 2 || U0[O0 + 1] == 1) {
            var $1 = O0 != 0 ? O0 - 1 : 2, a1 = n(
              $.thm[_0].s[c0][$1],
              i1,
              m * Z0
            );
            i1 = Math.min(i1, a1);
          }
          if (U0[O0] == 1) {
            var $1 = O0 != 0 ? O0 - 1 : 2, a1 = n(
              $.thm[_0].s[c0][$1],
              i1,
              O * Z0
            );
            i1 = Math.min(i1, a1);
          } else if (O0 != 0 && U0[O0 - 1] == 3 || O0 == 0 && $.nsPsy.lastAttacks[_0] == 3) {
            var $1 = O0 != 2 ? O0 + 1 : 0, a1 = n(
              $.thm[_0].s[c0][$1],
              i1,
              O * Z0
            );
            i1 = Math.min(i1, a1);
          }
          fe = r1[O0 * 3 + 3] + r1[O0 * 3 + 4] + r1[O0 * 3 + 5], r1[O0 * 3 + 5] * 6 < fe && (i1 *= 0.5, r1[O0 * 3 + 4] * 6 < fe && (i1 *= 0.5)), $.thm[_0].s[c0][O0] = i1;
        }
      }
      for ($.nsPsy.lastAttacks[_0] = U0[2], P0 = 0, B0 = 0; B0 < $.npart_l; B0++) {
        for (var w1 = $.s3ind[B0][0], me = N0[w1] * H[v1[w1]], I1 = $.s3_ll[P0++] * me; ++w1 <= $.s3ind[B0][1]; )
          me = N0[w1] * H[v1[w1]], I1 = a(
            I1,
            $.s3_ll[P0++] * me,
            w1,
            w1 - B0,
            $,
            0
          );
        I1 *= 0.158489319246111, $.blocktype_old[_0 & 1] == r0.SHORT_TYPE ? L0[B0] = I1 : L0[B0] = n(
          Math.min(I1, Math.min(z * $.nb_1[_0][B0], u0 * $.nb_2[_0][B0])),
          I1,
          Z0
        ), $.nb_2[_0][B0] = $.nb_1[_0][B0], $.nb_1[_0][B0] = I1;
      }
      for (; B0 <= r0.CBANDS; ++B0)
        N0[B0] = 0, L0[B0] = 0;
      i($, N0, L0, _0);
    }
    if ((v.mode == w.STEREO || v.mode == w.JOINT_STEREO) && v.interChRatio > 0 && V(v, v.interChRatio), v.mode == w.JOINT_STEREO) {
      var be;
      N($), be = v.msfix, Math.abs(be) > 0 && P($, be, v.ATHlower * $.ATH.adjust);
    }
    for (r(v, x0, e0, j), _0 = 0; _0 < k0; _0++) {
      var P1, Z1 = 0, z1, J1;
      _0 > 1 ? (P1 = G, Z1 = -2, z1 = r0.NORM_TYPE, (e0[0] == r0.SHORT_TYPE || e0[1] == r0.SHORT_TYPE) && (z1 = r0.SHORT_TYPE), J1 = c[y][_0 - 2]) : (P1 = C, Z1 = 0, z1 = e0[_0], J1 = k[y][_0]), z1 == r0.SHORT_TYPE ? P1[Z1 + _0] = Y(J1, $.masking_lower) : P1[Z1 + _0] = T(J1, $.masking_lower), v.analysis && ($.pinfo.pe[y][_0] = P1[Z1 + _0]);
    }
    return 0;
  };
  function d0(v, h, x, y, k, c, C, G) {
    var F = v.internal_flags;
    if (y < 2)
      Z.fft_long(F, C[G], y, h, x);
    else if (y == 2)
      for (var e0 = r0.BLKSIZE - 1; e0 >= 0; --e0) {
        var $ = C[G + 0][e0], a0 = C[G + 1][e0];
        C[G + 0][e0] = ($ + a0) * n1.SQRT2 * 0.5, C[G + 1][e0] = ($ - a0) * n1.SQRT2 * 0.5;
      }
    c[0] = C[G + 0][0], c[0] *= c[0];
    for (var e0 = r0.BLKSIZE / 2 - 1; e0 >= 0; --e0) {
      var m0 = C[G + 0][r0.BLKSIZE / 2 - e0], N0 = C[G + 0][r0.BLKSIZE / 2 + e0];
      c[r0.BLKSIZE / 2 - e0] = (m0 * m0 + N0 * N0) * 0.5;
    }
    {
      for (var n0 = 0, e0 = 11; e0 < r0.HBLKSIZE; e0++)
        n0 += c[e0];
      F.tot_ener[y] = n0;
    }
    if (v.analysis) {
      for (var e0 = 0; e0 < r0.HBLKSIZE; e0++)
        F.pinfo.energy[k][y][e0] = F.pinfo.energy_save[y][e0], F.pinfo.energy_save[y][e0] = c[e0];
      F.pinfo.pe[k][y] = F.pe[y];
    }
  }
  function M0(v, h, x, y, k, c, C, G) {
    var F = v.internal_flags;
    if (k == 0 && y < 2 && Z.fft_short(F, C[G], y, h, x), y == 2)
      for (var e0 = r0.BLKSIZE_s - 1; e0 >= 0; --e0) {
        var $ = C[G + 0][k][e0], a0 = C[G + 1][k][e0];
        C[G + 0][k][e0] = ($ + a0) * n1.SQRT2 * 0.5, C[G + 1][k][e0] = ($ - a0) * n1.SQRT2 * 0.5;
      }
    c[k][0] = C[G + 0][k][0], c[k][0] *= c[k][0];
    for (var e0 = r0.BLKSIZE_s / 2 - 1; e0 >= 0; --e0) {
      var m0 = C[G + 0][k][r0.BLKSIZE_s / 2 - e0], N0 = C[G + 0][k][r0.BLKSIZE_s / 2 + e0];
      c[k][r0.BLKSIZE_s / 2 - e0] = (m0 * m0 + N0 * N0) * 0.5;
    }
  }
  function R0(v, h, x, y) {
    var k = v.internal_flags;
    v.athaa_loudapprox == 2 && x < 2 && (k.loudness_sq[h][x] = k.loudness_sq_save[x], k.loudness_sq_save[x] = R(y, k));
  }
  var A0 = [
    -865163e-23 * 2,
    -851586e-8 * 2,
    -674764e-23 * 2,
    0.0209036 * 2,
    -336639e-22 * 2,
    -0.0438162 * 2,
    -154175e-22 * 2,
    0.0931738 * 2,
    -552212e-22 * 2,
    -0.313819 * 2
  ];
  function w0(v, h, x, y, k, c, C, G, F, e0) {
    for (var $ = m1([2, 576]), a0 = v.internal_flags, m0 = a0.channels_out, N0 = v.mode == w.JOINT_STEREO ? 4 : m0, n0 = 0; n0 < m0; n0++) {
      firbuf = h[n0];
      for (var L0 = x + 576 - 350 - K + 192, j = 0; j < 576; j++) {
        var x0, k0;
        x0 = firbuf[L0 + j + 10], k0 = 0;
        for (var _0 = 0; _0 < (K - 1) / 2 - 1; _0 += 2)
          x0 += A0[_0] * (firbuf[L0 + j + _0] + firbuf[L0 + j + K - _0]), k0 += A0[_0 + 1] * (firbuf[L0 + j + _0 + 1] + firbuf[L0 + j + K - _0 - 1]);
        $[n0][j] = x0 + k0;
      }
      k[y][n0].en.assign(a0.en[n0]), k[y][n0].thm.assign(a0.thm[n0]), N0 > 2 && (c[y][n0].en.assign(a0.en[n0 + 2]), c[y][n0].thm.assign(a0.thm[n0 + 2]));
    }
    for (var n0 = 0; n0 < N0; n0++) {
      var B0 = g0(12), l0 = g0(12), p0 = [0, 0, 0, 0], P0 = $[n0 & 1], c0 = 0, O0 = n0 == 3 ? a0.nsPsy.attackthre_s : a0.nsPsy.attackthre, X0 = 1;
      if (n0 == 2)
        for (var j = 0, _0 = 576; _0 > 0; ++j, --_0) {
          var Z0 = $[0][j], v1 = $[1][j];
          $[0][j] = Z0 + v1, $[1][j] = Z0 - v1;
        }
      for (var j = 0; j < 3; j++)
        l0[j] = a0.nsPsy.last_en_subshort[n0][j + 6], C0(a0.nsPsy.last_en_subshort[n0][j + 4] > 0), B0[j] = l0[j] / a0.nsPsy.last_en_subshort[n0][j + 4], p0[0] += l0[j];
      for (var j = 0; j < 9; j++) {
        for (var z0 = c0 + 64, K0 = 1; c0 < z0; c0++)
          K0 < Math.abs(P0[c0]) && (K0 = Math.abs(P0[c0]));
        a0.nsPsy.last_en_subshort[n0][j] = l0[j + 3] = K0, p0[1 + j / 3] += K0, K0 > l0[j + 3 - 2] ? (C0(l0[j + 3 - 2] > 0), K0 = K0 / l0[j + 3 - 2]) : l0[j + 3 - 2] > K0 * 10 ? K0 = l0[j + 3 - 2] / (K0 * 10) : K0 = 0, B0[j + 3] = K0;
      }
      for (var j = 0; j < 3; ++j) {
        var s1 = l0[j * 3 + 3] + l0[j * 3 + 4] + l0[j * 3 + 5], o1 = 1;
        l0[j * 3 + 5] * 6 < s1 && (o1 *= 0.5, l0[j * 3 + 4] * 6 < s1 && (o1 *= 0.5)), G[n0][j] = o1;
      }
      if (v.analysis) {
        for (var h1 = B0[0], j = 1; j < 12; j++)
          h1 < B0[j] && (h1 = B0[j]);
        a0.pinfo.ers[y][n0] = a0.pinfo.ers_save[n0], a0.pinfo.ers_save[n0] = h1;
      }
      for (var j = 0; j < 12; j++)
        F[n0][j / 3] == 0 && B0[j] > O0 && (F[n0][j / 3] = j % 3 + 1);
      for (var j = 1; j < 4; j++) {
        var c1 = p0[j - 1], S1 = p0[j], r1 = Math.max(c1, S1);
        r1 < 4e4 && c1 < 1.7 * S1 && S1 < 1.7 * c1 && (j == 1 && F[n0][0] <= F[n0][j] && (F[n0][0] = 0), F[n0][j] = 0);
      }
      F[n0][0] <= a0.nsPsy.lastAttacks[n0] && (F[n0][0] = 0), (a0.nsPsy.lastAttacks[n0] == 3 || F[n0][0] + F[n0][1] + F[n0][2] + F[n0][3] != 0) && (X0 = 0, F[n0][1] != 0 && F[n0][0] != 0 && (F[n0][1] = 0), F[n0][2] != 0 && F[n0][1] != 0 && (F[n0][2] = 0), F[n0][3] != 0 && F[n0][2] != 0 && (F[n0][3] = 0)), n0 < 2 ? e0[n0] = X0 : X0 == 0 && (e0[0] = e0[1] = 0), C[n0] = a0.tot_ener[n0];
    }
  }
  function $0(v, h, x) {
    if (x == 0)
      for (var y = 0; y < v.npart_s; y++)
        v.nb_s2[h][y] = v.nb_s1[h][y], v.nb_s1[h][y] = 0;
  }
  function f1(v, h) {
    for (var x = 0; x < v.npart_l; x++)
      v.nb_2[h][x] = v.nb_1[h][x], v.nb_1[h][x] = 0;
  }
  function t(v, h, x, y) {
    var k = H.length - 1, c = 0, C = x[c] + x[c + 1];
    if (C > 0) {
      var G = h[c];
      G < h[c + 1] && (G = h[c + 1]), C0(v.numlines_s[c] + v.numlines_s[c + 1] - 1 > 0), C = 20 * (G * 2 - C) / (C * (v.numlines_s[c] + v.numlines_s[c + 1] - 1));
      var F = 0 | C;
      F > k && (F = k), y[c] = F;
    } else
      y[c] = 0;
    for (c = 1; c < v.npart_s - 1; c++)
      if (C = x[c - 1] + x[c] + x[c + 1], C0(c + 1 < v.npart_s), C > 0) {
        var G = h[c - 1];
        G < h[c] && (G = h[c]), G < h[c + 1] && (G = h[c + 1]), C0(v.numlines_s[c - 1] + v.numlines_s[c] + v.numlines_s[c + 1] - 1 > 0), C = 20 * (G * 3 - C) / (C * (v.numlines_s[c - 1] + v.numlines_s[c] + v.numlines_s[c + 1] - 1));
        var F = 0 | C;
        F > k && (F = k), y[c] = F;
      } else
        y[c] = 0;
    if (C0(c == v.npart_s - 1), C = x[c - 1] + x[c], C > 0) {
      var G = h[c - 1];
      G < h[c] && (G = h[c]), C0(v.numlines_s[c - 1] + v.numlines_s[c] - 1 > 0), C = 20 * (G * 2 - C) / (C * (v.numlines_s[c - 1] + v.numlines_s[c] - 1));
      var F = 0 | C;
      F > k && (F = k), y[c] = F;
    } else
      y[c] = 0;
    C0(c == v.npart_s - 1);
  }
  function _(v, h, x, y, k, c) {
    var C = v.internal_flags, G = new float[r0.CBANDS](), F = g0(r0.CBANDS), e0, $, a0, m0 = new int[r0.CBANDS]();
    for (a0 = $ = 0; a0 < C.npart_s; ++a0) {
      var N0 = 0, n0 = 0, L0 = C.numlines_s[a0];
      for (e0 = 0; e0 < L0; ++e0, ++$) {
        var j = h[c][$];
        N0 += j, n0 < j && (n0 = j);
      }
      x[a0] = N0, G[a0] = n0, F[a0] = N0 / L0, C0(F[a0] >= 0);
    }
    for (C0(a0 == C.npart_s); a0 < r0.CBANDS; ++a0)
      G[a0] = 0, F[a0] = 0;
    for (t(C, G, F, m0), $ = a0 = 0; a0 < C.npart_s; a0++) {
      var x0 = C.s3ind_s[a0][0], k0 = C.s3ind_s[a0][1], _0, B0, l0, p0, P0;
      for (_0 = m0[x0], B0 = 1, p0 = C.s3_ss[$] * x[x0] * H[m0[x0]], ++$, ++x0; x0 <= k0; )
        _0 += m0[x0], B0 += 1, l0 = C.s3_ss[$] * x[x0] * H[m0[x0]], p0 = L(p0, l0, x0 - a0), ++$, ++x0;
      _0 = (1 + 2 * _0) / (2 * B0), P0 = H[_0] * 0.5, p0 *= P0, y[a0] = p0, C.nb_s2[k][a0] = C.nb_s1[k][a0], C.nb_s1[k][a0] = p0, l0 = G[a0], l0 *= C.minval_s[a0], l0 *= P0, y[a0] > l0 && (y[a0] = l0), C.masking_lower > 1 && (y[a0] *= C.masking_lower), y[a0] > x[a0] && (y[a0] = x[a0]), C.masking_lower < 1 && (y[a0] *= C.masking_lower), C0(y[a0] >= 0);
    }
    for (; a0 < r0.CBANDS; ++a0)
      x[a0] = 0, y[a0] = 0;
  }
  function S0(v, h, x, y, k) {
    var c = g0(r0.CBANDS), C = g0(r0.CBANDS), G = L1(r0.CBANDS + 2), F;
    q(v, h, x, c, C), i0(v, c, C, G);
    var e0 = 0;
    for (F = 0; F < v.npart_l; F++) {
      var $, a0, m0, N0, n0 = v.s3ind[F][0], L0 = v.s3ind[F][1], j = 0, x0 = 0;
      for (j = G[n0], x0 += 1, a0 = v.s3_ll[e0] * x[n0] * H[G[n0]], ++e0, ++n0; n0 <= L0; )
        j += G[n0], x0 += 1, $ = v.s3_ll[e0] * x[n0] * H[G[n0]], N0 = L(a0, $, n0 - F), a0 = N0, ++e0, ++n0;
      if (j = (1 + 2 * j) / (2 * x0), m0 = H[j] * 0.5, a0 *= m0, v.blocktype_old[k & 1] == r0.SHORT_TYPE) {
        var k0 = z * v.nb_1[k][F];
        k0 > 0 ? y[F] = Math.min(a0, k0) : y[F] = Math.min(a0, x[F] * O);
      } else {
        var _0 = u0 * v.nb_2[k][F], B0 = z * v.nb_1[k][F], k0;
        _0 <= 0 && (_0 = a0), B0 <= 0 && (B0 = a0), v.blocktype_old[k & 1] == r0.NORM_TYPE ? k0 = Math.min(B0, _0) : k0 = B0, y[F] = Math.min(a0, k0);
      }
      v.nb_2[k][F] = v.nb_1[k][F], v.nb_1[k][F] = a0, $ = c[F], $ *= v.minval_l[F], $ *= m0, y[F] > $ && (y[F] = $), v.masking_lower > 1 && (y[F] *= v.masking_lower), y[F] > x[F] && (y[F] = x[F]), v.masking_lower < 1 && (y[F] *= v.masking_lower), C0(y[F] >= 0);
    }
    for (; F < r0.CBANDS; ++F)
      x[F] = 0, y[F] = 0;
  }
  function E0(v, h) {
    var x = v.internal_flags;
    v.short_blocks == F1.short_block_coupled && !(h[0] != 0 && h[1] != 0) && (h[0] = h[1] = 0);
    for (var y = 0; y < x.channels_out; y++)
      v.short_blocks == F1.short_block_dispensed && (h[y] = 1), v.short_blocks == F1.short_block_forced && (h[y] = 0);
  }
  function V0(v, h, x) {
    for (var y = v.internal_flags, k = 0; k < y.channels_out; k++) {
      var c = r0.NORM_TYPE;
      h[k] != 0 ? (C0(y.blocktype_old[k] != r0.START_TYPE), y.blocktype_old[k] == r0.SHORT_TYPE && (c = r0.STOP_TYPE)) : (c = r0.SHORT_TYPE, y.blocktype_old[k] == r0.NORM_TYPE && (y.blocktype_old[k] = r0.START_TYPE), y.blocktype_old[k] == r0.STOP_TYPE && (y.blocktype_old[k] = r0.SHORT_TYPE)), x[k] = y.blocktype_old[k], y.blocktype_old[k] = c;
    }
  }
  function H0(v, h, x, y, k, c, C) {
    for (var G = c * 2, F = c > 0 ? Math.pow(10, k) : 1, e0, $, a0 = 0; a0 < C; ++a0) {
      var m0 = v[2][a0], N0 = v[3][a0], n0 = h[0][a0], L0 = h[1][a0], j = h[2][a0], x0 = h[3][a0];
      if (n0 <= 1.58 * L0 && L0 <= 1.58 * n0) {
        var k0 = x[a0] * N0, _0 = x[a0] * m0;
        $ = Math.max(j, Math.min(x0, k0)), e0 = Math.max(x0, Math.min(j, _0));
      } else
        $ = j, e0 = x0;
      if (c > 0) {
        var B0, l0, p0 = y[a0] * F;
        if (B0 = Math.min(Math.max(n0, p0), Math.max(L0, p0)), j = Math.max($, p0), x0 = Math.max(e0, p0), l0 = j + x0, l0 > 0 && B0 * G < l0) {
          var P0 = B0 * G / l0;
          j *= P0, x0 *= P0;
        }
        $ = Math.min(j, $), e0 = Math.min(x0, e0);
      }
      $ > m0 && ($ = m0), e0 > N0 && (e0 = N0), h[2][a0] = $, h[3][a0] = e0;
    }
  }
  this.L3psycho_anal_vbr = function(v, h, x, y, k, c, C, G, F, e0) {
    var $ = v.internal_flags, a0, m0, N0 = g0(r0.HBLKSIZE), n0 = m1([3, r0.HBLKSIZE_s]), L0 = m1([2, r0.BLKSIZE]), j = m1([2, 3, r0.BLKSIZE_s]), x0 = m1([4, r0.CBANDS]), k0 = m1([4, r0.CBANDS]), _0 = m1([4, 3]), B0 = 0.6, l0 = [
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0]
    ], p0 = L1(2), P0 = v.mode == w.JOINT_STEREO ? 4 : $.channels_out;
    w0(
      v,
      h,
      x,
      y,
      k,
      c,
      F,
      _0,
      l0,
      p0
    ), E0(v, p0);
    {
      for (var c0 = 0; c0 < P0; c0++) {
        var O0 = c0 & 1;
        a0 = L0, d0(
          v,
          h,
          x,
          c0,
          y,
          N0,
          a0,
          O0
        ), R0(
          v,
          y,
          c0,
          N0
        ), p0[O0] != 0 ? S0(
          $,
          N0,
          x0[c0],
          k0[c0],
          c0
        ) : f1($, c0);
      }
      p0[0] + p0[1] == 2 && v.mode == w.JOINT_STEREO && H0(
        x0,
        k0,
        $.mld_cb_l,
        $.ATH.cb_l,
        v.ATHlower * $.ATH.adjust,
        v.msfix,
        $.npart_l
      );
      for (var c0 = 0; c0 < P0; c0++) {
        var O0 = c0 & 1;
        p0[O0] != 0 && i($, x0[c0], k0[c0], c0);
      }
    }
    {
      for (var X0 = 0; X0 < 3; X0++) {
        for (var c0 = 0; c0 < P0; ++c0) {
          var O0 = c0 & 1;
          p0[O0] != 0 ? $0($, c0, X0) : (m0 = j, M0(
            v,
            h,
            x,
            c0,
            X0,
            n0,
            m0,
            O0
          ), _(
            v,
            n0,
            x0[c0],
            k0[c0],
            c0,
            X0
          ));
        }
        p0[0] + p0[1] == 0 && v.mode == w.JOINT_STEREO && H0(
          x0,
          k0,
          $.mld_cb_s,
          $.ATH.cb_s,
          v.ATHlower * $.ATH.adjust,
          v.msfix,
          $.npart_s
        );
        for (var c0 = 0; c0 < P0; ++c0) {
          var O0 = c0 & 1;
          p0[O0] == 0 && E(
            $,
            x0[c0],
            k0[c0],
            c0,
            X0
          );
        }
      }
      for (var c0 = 0; c0 < P0; c0++) {
        var O0 = c0 & 1;
        if (p0[O0] == 0)
          for (var Z0 = 0; Z0 < r0.SBMAX_s; Z0++) {
            for (var v1 = g0(3), X0 = 0; X0 < 3; X0++) {
              var z0 = $.thm[c0].s[Z0][X0];
              if (z0 *= A, l0[c0][X0] >= 2 || l0[c0][X0 + 1] == 1) {
                var K0 = X0 != 0 ? X0 - 1 : 2, s1 = n(
                  $.thm[c0].s[Z0][K0],
                  z0,
                  m * B0
                );
                z0 = Math.min(z0, s1);
              } else if (l0[c0][X0] == 1) {
                var K0 = X0 != 0 ? X0 - 1 : 2, s1 = n(
                  $.thm[c0].s[Z0][K0],
                  z0,
                  O * B0
                );
                z0 = Math.min(z0, s1);
              } else if (X0 != 0 && l0[c0][X0 - 1] == 3 || X0 == 0 && $.nsPsy.lastAttacks[c0] == 3) {
                var K0 = X0 != 2 ? X0 + 1 : 0, s1 = n(
                  $.thm[c0].s[Z0][K0],
                  z0,
                  O * B0
                );
                z0 = Math.min(z0, s1);
              }
              z0 *= _0[c0][X0], v1[X0] = z0;
            }
            for (var X0 = 0; X0 < 3; X0++)
              $.thm[c0].s[Z0][X0] = v1[X0];
          }
      }
    }
    for (var c0 = 0; c0 < P0; c0++)
      $.nsPsy.lastAttacks[c0] = l0[c0][2];
    V0(v, p0, e0);
    for (var c0 = 0; c0 < P0; c0++) {
      var o1, h1, c1, S1;
      c0 > 1 ? (o1 = G, h1 = -2, c1 = r0.NORM_TYPE, (e0[0] == r0.SHORT_TYPE || e0[1] == r0.SHORT_TYPE) && (c1 = r0.SHORT_TYPE), S1 = c[y][c0 - 2]) : (o1 = C, h1 = 0, c1 = e0[c0], S1 = k[y][c0]), c1 == r0.SHORT_TYPE ? o1[h1 + c0] = Y(S1, $.masking_lower) : o1[h1 + c0] = T(S1, $.masking_lower), v.analysis && ($.pinfo.pe[y][c0] = o1[h1 + c0]);
    }
    return 0;
  };
  function y0(v, h) {
    var x = v, y;
    return x >= 0 ? y = -x * 27 : y = x * h, y <= -72 ? 0 : Math.exp(y * t0);
  }
  function T0(v) {
    var h = 0, x = 0;
    {
      var y = 0, k, c;
      for (y = 0; y0(y, v) > 1e-20; y -= 1)
        ;
      for (k = y, c = 0; Math.abs(c - k) > 1e-12; )
        y = (c + k) / 2, y0(y, v) > 0 ? c = y : k = y;
      h = k;
    }
    {
      var y = 0, k, c;
      for (y = 0; y0(y, v) > 1e-20; y += 1)
        ;
      for (k = 0, c = y; Math.abs(c - k) > 1e-12; )
        y = (c + k) / 2, y0(y, v) > 0 ? k = y : c = y;
      x = c;
    }
    {
      var C = 0, G = 1e3, F;
      for (F = 0; F <= G; ++F) {
        var y = h + F * (x - h) / G, e0 = y0(y, v);
        C += e0;
      }
      {
        var $ = (G + 1) / (C * (x - h));
        return $;
      }
    }
  }
  function F0(v) {
    var h, x, y, k;
    return h = v, h >= 0 ? h *= 3 : h *= 1.5, h >= 0.5 && h <= 2.5 ? (k = h - 0.5, x = 8 * (k * k - 2 * k)) : x = 0, h += 0.474, y = 15.811389 + 7.5 * h - 17.5 * Math.sqrt(1 + h * h), y <= -60 ? 0 : (h = Math.exp((x + y) * t0), h /= 0.6609193, h);
  }
  function I0(v) {
    return v < 0 && (v = 0), v = v * 1e-3, 13 * Math.atan(0.76 * v) + 3.5 * Math.atan(v * v / (7.5 * 7.5));
  }
  function b0(v, h, x, y, k, c, C, G, F, e0, $, a0) {
    var m0 = g0(r0.CBANDS + 1), N0 = G / (a0 > 15 ? 2 * 576 : 2 * 192), n0 = L1(r0.HBLKSIZE), L0;
    G /= F;
    var j = 0, x0 = 0;
    for (L0 = 0; L0 < r0.CBANDS; L0++) {
      var k0, _0;
      for (k0 = I0(G * j), m0[L0] = G * j, _0 = j; I0(G * _0) - k0 < D && _0 <= F / 2; _0++)
        ;
      for (v[L0] = _0 - j, x0 = L0 + 1; j < _0; )
        C0(j < r0.HBLKSIZE), n0[j++] = L0;
      if (j > F / 2) {
        j = F / 2, ++L0;
        break;
      }
    }
    C0(L0 < r0.CBANDS), m0[L0] = G * j;
    for (var B0 = 0; B0 < a0; B0++) {
      var l0, p0, P0, c0, O0;
      P0 = e0[B0], c0 = e0[B0 + 1], l0 = 0 | Math.floor(0.5 + $ * (P0 - 0.5)), l0 < 0 && (l0 = 0), p0 = 0 | Math.floor(0.5 + $ * (c0 - 0.5)), p0 > F / 2 && (p0 = F / 2), x[B0] = (n0[l0] + n0[p0]) / 2, h[B0] = n0[p0];
      var X0 = N0 * c0;
      C[B0] = (X0 - m0[h[B0]]) / (m0[h[B0] + 1] - m0[h[B0]]), C[B0] < 0 ? C[B0] = 0 : C[B0] > 1 && (C[B0] = 1), O0 = I0(G * e0[B0] * $), O0 = Math.min(O0, 15.5) / 15.5, c[B0] = Math.pow(
        10,
        1.25 * (1 - Math.cos(Math.PI * O0)) - 2.5
      );
    }
    j = 0;
    for (var Z0 = 0; Z0 < x0; Z0++) {
      var v1 = v[Z0], k0, z0;
      k0 = I0(G * j), z0 = I0(G * (j + v1 - 1)), y[Z0] = 0.5 * (k0 + z0), k0 = I0(G * (j - 0.5)), z0 = I0(G * (j + v1 - 0.5)), k[Z0] = z0 - k0, j += v1;
    }
    return x0;
  }
  function G0(v, h, x, y, k, c) {
    var C = m1([r0.CBANDS, r0.CBANDS]), G, F = 0;
    if (c)
      for (var e0 = 0; e0 < h; e0++)
        for (G = 0; G < h; G++) {
          var $ = F0(x[e0] - x[G]) * y[G];
          C[e0][G] = $ * k[e0];
        }
    else
      for (G = 0; G < h; G++)
        for (var a0 = 15 + Math.min(21 / x[G], 12), m0 = T0(a0), e0 = 0; e0 < h; e0++) {
          var $ = m0 * y0(x[e0] - x[G], a0) * y[G];
          C[e0][G] = $ * k[e0];
        }
    for (var e0 = 0; e0 < h; e0++) {
      for (G = 0; G < h && !(C[e0][G] > 0); G++)
        ;
      for (v[e0][0] = G, G = h - 1; G > 0 && !(C[e0][G] > 0); G--)
        ;
      v[e0][1] = G, F += v[e0][1] - v[e0][0] + 1;
    }
    for (var N0 = g0(F), n0 = 0, e0 = 0; e0 < h; e0++)
      for (G = v[e0][0]; G <= v[e0][1]; G++)
        N0[n0++] = C[e0][G];
    return N0;
  }
  function e1(v) {
    var h = I0(v);
    return h = Math.min(h, 15.5) / 15.5, Math.pow(
      10,
      1.25 * (1 - Math.cos(Math.PI * h)) - 2.5
    );
  }
  this.psymodel_init = function(v) {
    var h = v.internal_flags, x, y = !0, k = 13, c = 24, C = 0, G = 0, F = -8.25, e0 = -4.5, $ = g0(r0.CBANDS), a0 = g0(r0.CBANDS), m0 = g0(r0.CBANDS), N0 = v.out_samplerate;
    switch (v.experimentalZ) {
      default:
      case 0:
        y = !0;
        break;
      case 1:
        y = !(v.VBR == C1.vbr_mtrh || v.VBR == C1.vbr_mt);
        break;
      case 2:
        y = !1;
        break;
      case 3:
        k = 8, C = -1.75, G = -0.0125, F = -8.25, e0 = -2.25;
        break;
    }
    for (h.ms_ener_ratio_old = 0.25, h.blocktype_old[0] = h.blocktype_old[1] = r0.NORM_TYPE, x = 0; x < 4; ++x) {
      for (var j = 0; j < r0.CBANDS; ++j)
        h.nb_1[x][j] = 1e20, h.nb_2[x][j] = 1e20, h.nb_s1[x][j] = h.nb_s2[x][j] = 1;
      for (var n0 = 0; n0 < r0.SBMAX_l; n0++)
        h.en[x].l[n0] = 1e20, h.thm[x].l[n0] = 1e20;
      for (var j = 0; j < 3; ++j) {
        for (var n0 = 0; n0 < r0.SBMAX_s; n0++)
          h.en[x].s[n0][j] = 1e20, h.thm[x].s[n0][j] = 1e20;
        h.nsPsy.lastAttacks[x] = 0;
      }
      for (var j = 0; j < 9; j++)
        h.nsPsy.last_en_subshort[x][j] = 10;
    }
    for (h.loudness_sq_save[0] = h.loudness_sq_save[1] = 0, h.npart_l = b0(
      h.numlines_l,
      h.bo_l,
      h.bm_l,
      $,
      a0,
      h.mld_l,
      h.PSY.bo_l_weight,
      N0,
      r0.BLKSIZE,
      h.scalefac_band.l,
      r0.BLKSIZE / (2 * 576),
      r0.SBMAX_l
    ), C0(h.npart_l < r0.CBANDS), x = 0; x < h.npart_l; x++) {
      var L0 = C;
      $[x] >= k && (L0 = G * ($[x] - k) / (c - k) + C * (c - $[x]) / (c - k)), m0[x] = Math.pow(10, L0 / 10), h.numlines_l[x] > 0 ? h.rnumlines_l[x] = 1 / h.numlines_l[x] : h.rnumlines_l[x] = 0;
    }
    h.s3_ll = G0(
      h.s3ind,
      h.npart_l,
      $,
      a0,
      m0,
      y
    );
    var j = 0;
    for (x = 0; x < h.npart_l; x++) {
      var x0;
      x0 = Ue.MAX_VALUE;
      for (var k0 = 0; k0 < h.numlines_l[x]; k0++, j++) {
        var _0 = N0 * j / (1e3 * r0.BLKSIZE), B0;
        B0 = this.ATHformula(_0 * 1e3, v) - 20, B0 = Math.pow(10, 0.1 * B0), B0 *= h.numlines_l[x], x0 > B0 && (x0 = B0);
      }
      h.ATH.cb_l[x] = x0, x0 = -20 + $[x] * 20 / 10, x0 > 6 && (x0 = 100), x0 < -15 && (x0 = -15), x0 -= 8, h.minval_l[x] = Math.pow(10, x0 / 10) * h.numlines_l[x];
    }
    for (h.npart_s = b0(
      h.numlines_s,
      h.bo_s,
      h.bm_s,
      $,
      a0,
      h.mld_s,
      h.PSY.bo_s_weight,
      N0,
      r0.BLKSIZE_s,
      h.scalefac_band.s,
      r0.BLKSIZE_s / (2 * 192),
      r0.SBMAX_s
    ), C0(h.npart_s < r0.CBANDS), j = 0, x = 0; x < h.npart_s; x++) {
      var x0, L0 = F;
      $[x] >= k && (L0 = e0 * ($[x] - k) / (c - k) + F * (c - $[x]) / (c - k)), m0[x] = Math.pow(10, L0 / 10), x0 = Ue.MAX_VALUE;
      for (var k0 = 0; k0 < h.numlines_s[x]; k0++, j++) {
        var _0 = N0 * j / (1e3 * r0.BLKSIZE_s), B0;
        B0 = this.ATHformula(_0 * 1e3, v) - 20, B0 = Math.pow(10, 0.1 * B0), B0 *= h.numlines_s[x], x0 > B0 && (x0 = B0);
      }
      h.ATH.cb_s[x] = x0, x0 = -7 + $[x] * 7 / 12, $[x] > 12 && (x0 *= 1 + Math.log(1 + x0) * 3.1), $[x] < 12 && (x0 *= 1 + Math.log(1 - x0) * 2.3), x0 < -15 && (x0 = -15), x0 -= 8, h.minval_s[x] = Math.pow(10, x0 / 10) * h.numlines_s[x];
    }
    h.s3_ss = G0(
      h.s3ind_s,
      h.npart_s,
      $,
      a0,
      m0,
      y
    ), B(), Z.init_fft(h), h.decay = Math.exp(-1 * X / (f0 * N0 / 192));
    {
      var l0;
      l0 = s0, v.exp_nspsytune & 2 && (l0 = 1), Math.abs(v.msfix) > 0 && (l0 = v.msfix), v.msfix = l0;
      for (var p0 = 0; p0 < h.npart_l; p0++)
        h.s3ind[p0][1] > h.npart_l - 1 && (h.s3ind[p0][1] = h.npart_l - 1);
    }
    var P0 = 576 * h.mode_gr / N0;
    if (h.ATH.decay = Math.pow(10, -12 / 10 * P0), h.ATH.adjust = 0.01, h.ATH.adjustLimit = 1, C0(h.bo_l[r0.SBMAX_l - 1] <= h.npart_l), C0(h.bo_s[r0.SBMAX_s - 1] <= h.npart_s), v.ATHtype != -1) {
      var _0, c0 = v.out_samplerate / r0.BLKSIZE, O0 = 0;
      for (_0 = 0, x = 0; x < r0.BLKSIZE / 2; ++x)
        _0 += c0, h.ATH.eql_w[x] = 1 / Math.pow(10, this.ATHformula(_0, v) / 10), O0 += h.ATH.eql_w[x];
      for (O0 = 1 / O0, x = r0.BLKSIZE / 2; --x >= 0; )
        h.ATH.eql_w[x] *= O0;
    }
    {
      for (var p0 = j = 0; p0 < h.npart_s; ++p0)
        for (x = 0; x < h.numlines_s[p0]; ++x)
          ++j;
      for (var p0 = j = 0; p0 < h.npart_l; ++p0)
        for (x = 0; x < h.numlines_l[p0]; ++x)
          ++j;
    }
    for (j = 0, x = 0; x < h.npart_l; x++) {
      var _0 = N0 * (j + h.numlines_l[x] / 2) / (1 * r0.BLKSIZE);
      h.mld_cb_l[x] = e1(_0), j += h.numlines_l[x];
    }
    for (; x < r0.CBANDS; ++x)
      h.mld_cb_l[x] = 1;
    for (j = 0, x = 0; x < h.npart_s; x++) {
      var _0 = N0 * (j + h.numlines_s[x] / 2) / (1 * r0.BLKSIZE_s);
      h.mld_cb_s[x] = e1(_0), j += h.numlines_s[x];
    }
    for (; x < r0.CBANDS; ++x)
      h.mld_cb_s[x] = 1;
    return 0;
  };
  function Y0(v, h) {
    v < -0.3 && (v = 3410), v /= 1e3, v = Math.max(0.1, v);
    var x = 3.64 * Math.pow(v, -0.8) - 6.8 * Math.exp(-0.6 * Math.pow(v - 3.4, 2)) + 6 * Math.exp(-0.15 * Math.pow(v - 8.7, 2)) + (0.6 + 0.04 * h) * 1e-3 * Math.pow(v, 4);
    return x;
  }
  this.ATHformula = function(v, h) {
    var x;
    switch (h.ATHtype) {
      case 0:
        x = Y0(v, 9);
        break;
      case 1:
        x = Y0(v, -1);
        break;
      case 2:
        x = Y0(v, 0);
        break;
      case 3:
        x = Y0(v, 1) + 6;
        break;
      case 4:
        x = Y0(v, h.ATHcurve);
        break;
      default:
        x = Y0(v, 0);
        break;
    }
    return x;
  };
}
var Qa = Ua, Wa = j1;
function ja() {
  this.class_id = 0, this.num_samples = 0, this.num_channels = 0, this.in_samplerate = 0, this.out_samplerate = 0, this.scale = 0, this.scale_left = 0, this.scale_right = 0, this.analysis = !1, this.bWriteVbrTag = !1, this.decode_only = !1, this.quality = 0, this.mode = Wa.STEREO, this.force_ms = !1, this.free_format = !1, this.findReplayGain = !1, this.decode_on_the_fly = !1, this.write_id3tag_automatic = !1, this.brate = 0, this.compression_ratio = 0, this.copyright = 0, this.original = 0, this.extension = 0, this.emphasis = 0, this.error_protection = 0, this.strict_ISO = !1, this.disable_reservoir = !1, this.quant_comp = 0, this.quant_comp_short = 0, this.experimentalY = !1, this.experimentalZ = 0, this.exp_nspsytune = 0, this.preset = 0, this.VBR = null, this.VBR_q_frac = 0, this.VBR_q = 0, this.VBR_mean_bitrate_kbps = 0, this.VBR_min_bitrate_kbps = 0, this.VBR_max_bitrate_kbps = 0, this.VBR_hard_min = 0, this.lowpassfreq = 0, this.highpassfreq = 0, this.lowpasswidth = 0, this.highpasswidth = 0, this.maskingadjust = 0, this.maskingadjust_short = 0, this.ATHonly = !1, this.ATHshort = !1, this.noATH = !1, this.ATHtype = 0, this.ATHcurve = 0, this.ATHlower = 0, this.athaa_type = 0, this.athaa_loudapprox = 0, this.athaa_sensitivity = 0, this.short_blocks = null, this.useTemporal = !1, this.interChRatio = 0, this.msfix = 0, this.tune = !1, this.tune_value_a = 0, this.version = 0, this.encoder_delay = 0, this.encoder_padding = 0, this.framesize = 0, this.frameNum = 0, this.lame_allocated_gfp = 0, this.internal_flags = null;
}
var za = ja, Ja = t1(), Ta = {};
Ta.SFBMAX = Ja.SBMAX_s * 3;
var ie = Ta, ya = Q0, ga = ya.new_float, N1 = ya.new_int, Re = ie;
function e2() {
  this.xr = ga(576), this.l3_enc = N1(576), this.scalefac = N1(Re.SFBMAX), this.xrpow_max = 0, this.part2_3_length = 0, this.big_values = 0, this.count1 = 0, this.global_gain = 0, this.scalefac_compress = 0, this.block_type = 0, this.mixed_block_flag = 0, this.table_select = N1(3), this.subblock_gain = N1(3 + 1), this.region0_count = 0, this.region1_count = 0, this.preflag = 0, this.scalefac_scale = 0, this.count1table_select = 0, this.part2_length = 0, this.sfb_lmax = 0, this.sfb_smin = 0, this.psy_lmax = 0, this.sfbmax = 0, this.psymax = 0, this.sfbdivide = 0, this.width = N1(Re.SFBMAX), this.window = N1(Re.SFBMAX), this.count1bits = 0, this.sfb_partition_table = null, this.slen = N1(4), this.max_nonzero_coeff = 0;
  var w = this;
  function Z(z) {
    return new Int32Array(z);
  }
  function X(z) {
    return new Float32Array(z);
  }
  this.assign = function(z) {
    w.xr = X(z.xr), w.l3_enc = Z(z.l3_enc), w.scalefac = Z(z.scalefac), w.xrpow_max = z.xrpow_max, w.part2_3_length = z.part2_3_length, w.big_values = z.big_values, w.count1 = z.count1, w.global_gain = z.global_gain, w.scalefac_compress = z.scalefac_compress, w.block_type = z.block_type, w.mixed_block_flag = z.mixed_block_flag, w.table_select = Z(z.table_select), w.subblock_gain = Z(z.subblock_gain), w.region0_count = z.region0_count, w.region1_count = z.region1_count, w.preflag = z.preflag, w.scalefac_scale = z.scalefac_scale, w.count1table_select = z.count1table_select, w.part2_length = z.part2_length, w.sfb_lmax = z.sfb_lmax, w.sfb_smin = z.sfb_smin, w.psy_lmax = z.psy_lmax, w.sfbmax = z.sfbmax, w.psymax = z.psymax, w.sfbdivide = z.sfbdivide, w.width = Z(z.width), w.window = Z(z.window), w.count1bits = z.count1bits, w.sfb_partition_table = z.sfb_partition_table.slice(0), w.slen = Z(z.slen), w.max_nonzero_coeff = z.max_nonzero_coeff;
  };
}
var Le = e2, a2 = Q0, Qe = a2.new_int, r2 = Le;
function t2() {
  this.tt = [[null, null], [null, null]], this.main_data_begin = 0, this.private_bits = 0, this.resvDrain_pre = 0, this.resvDrain_post = 0, this.scfsi = [Qe(4), Qe(4)];
  for (var w = 0; w < 2; w++)
    for (var Z = 0; Z < 2; Z++)
      this.tt[w][Z] = new r2();
}
var s2 = t2, wa = Q0, g1 = wa.System, ee = wa.new_int, ae = t1();
function i2(w, Z, X, z) {
  this.l = ee(1 + ae.SBMAX_l), this.s = ee(1 + ae.SBMAX_s), this.psfb21 = ee(1 + ae.PSFB21), this.psfb12 = ee(1 + ae.PSFB12);
  var u0 = this.l, W = this.s;
  arguments.length == 4 && (this.arrL = arguments[0], this.arrS = arguments[1], this.arr21 = arguments[2], this.arr12 = arguments[3], g1.arraycopy(this.arrL, 0, u0, 0, Math.min(this.arrL.length, this.l.length)), g1.arraycopy(this.arrS, 0, W, 0, Math.min(this.arrS.length, this.s.length)), g1.arraycopy(this.arr21, 0, this.psfb21, 0, Math.min(this.arr21.length, this.psfb21.length)), g1.arraycopy(this.arr12, 0, this.psfb12, 0, Math.min(this.arr12.length, this.psfb12.length)));
}
var Ia = i2, Ne = Q0, xe = Ne.new_float, n2 = Ne.new_float_n, _2 = Ne.new_int, We = t1();
function l2() {
  this.last_en_subshort = n2([4, 9]), this.lastAttacks = _2(4), this.pefirbuf = xe(19), this.longfact = xe(We.SBMAX_l), this.shortfact = xe(We.SBMAX_s), this.attackthre = 0, this.attackthre_s = 0;
}
var v2 = l2;
function o2() {
  this.sum = 0, this.seen = 0, this.want = 0, this.pos = 0, this.size = 0, this.bag = null, this.nVbrNumFrames = 0, this.nBytesWritten = 0, this.TotalFrameSize = 0;
}
var h2 = o2, Y1 = Q0, u2 = Y1.new_byte, f2 = Y1.new_double, b1 = Y1.new_float, p1 = Y1.new_float_n, d1 = Y1.new_int, re = Y1.new_int_n, m2 = s2, b2 = Ia, c2 = v2, S2 = h2, je = Ea(), W0 = t1(), d2 = ie;
E1.MFSIZE = 3 * 1152 + W0.ENCDELAY - W0.MDCTDELAY;
E1.MAX_HEADER_BUF = 256;
E1.MAX_BITS_PER_CHANNEL = 4095;
E1.MAX_BITS_PER_GRANULE = 7680;
E1.BPC = 320;
function E1() {
  var w = 40;
  this.Class_ID = 0, this.lame_encode_frame_init = 0, this.iteration_init_init = 0, this.fill_buffer_resample_init = 0, this.mfbuf = p1([2, E1.MFSIZE]), this.mode_gr = 0, this.channels_in = 0, this.channels_out = 0, this.resample_ratio = 0, this.mf_samples_to_encode = 0, this.mf_size = 0, this.VBR_min_bitrate = 0, this.VBR_max_bitrate = 0, this.bitrate_index = 0, this.samplerate_index = 0, this.mode_ext = 0, this.lowpass1 = 0, this.lowpass2 = 0, this.highpass1 = 0, this.highpass2 = 0, this.noise_shaping = 0, this.noise_shaping_amp = 0, this.substep_shaping = 0, this.psymodel = 0, this.noise_shaping_stop = 0, this.subblock_gain = 0, this.use_best_huffman = 0, this.full_outer_loop = 0, this.l3_side = new m2(), this.ms_ratio = b1(2), this.padding = 0, this.frac_SpF = 0, this.slot_lag = 0, this.tag_spec = null, this.nMusicCRC = 0, this.OldValue = d1(2), this.CurrentStep = d1(2), this.masking_lower = 0, this.bv_scf = d1(576), this.pseudohalf = d1(d2.SFBMAX), this.sfb21_extra = !1, this.inbuf_old = new Array(2), this.blackfilt = new Array(2 * E1.BPC + 1), this.itime = f2(2), this.sideinfo_len = 0, this.sb_sample = p1([2, 2, 18, W0.SBLIMIT]), this.amp_filter = b1(32);
  function Z() {
    this.write_timing = 0, this.ptr = 0, this.buf = u2(w);
  }
  this.header = new Array(E1.MAX_HEADER_BUF), this.h_ptr = 0, this.w_ptr = 0, this.ancillary_flag = 0, this.ResvSize = 0, this.ResvMax = 0, this.scalefac_band = new b2(), this.minval_l = b1(W0.CBANDS), this.minval_s = b1(W0.CBANDS), this.nb_1 = p1([4, W0.CBANDS]), this.nb_2 = p1([4, W0.CBANDS]), this.nb_s1 = p1([4, W0.CBANDS]), this.nb_s2 = p1([4, W0.CBANDS]), this.s3_ss = null, this.s3_ll = null, this.decay = 0, this.thm = new Array(4), this.en = new Array(4), this.tot_ener = b1(4), this.loudness_sq = p1([2, 2]), this.loudness_sq_save = b1(2), this.mld_l = b1(W0.SBMAX_l), this.mld_s = b1(W0.SBMAX_s), this.bm_l = d1(W0.SBMAX_l), this.bo_l = d1(W0.SBMAX_l), this.bm_s = d1(W0.SBMAX_s), this.bo_s = d1(W0.SBMAX_s), this.npart_l = 0, this.npart_s = 0, this.s3ind = re([W0.CBANDS, 2]), this.s3ind_s = re([W0.CBANDS, 2]), this.numlines_s = d1(W0.CBANDS), this.numlines_l = d1(W0.CBANDS), this.rnumlines_l = b1(W0.CBANDS), this.mld_cb_l = b1(W0.CBANDS), this.mld_cb_s = b1(W0.CBANDS), this.numlines_s_num1 = 0, this.numlines_l_num1 = 0, this.pe = b1(4), this.ms_ratio_s_old = 0, this.ms_ratio_l_old = 0, this.ms_ener_ratio_old = 0, this.blocktype_old = d1(2), this.nsPsy = new c2(), this.VBR_seek_table = new S2(), this.ATH = null, this.PSY = null, this.nogap_total = 0, this.nogap_current = 0, this.decode_on_the_fly = !0, this.findReplayGain = !0, this.findPeakSample = !0, this.PeakSample = 0, this.RadioGain = 0, this.AudiophileGain = 0, this.rgdata = null, this.noclipGainChange = 0, this.noclipScale = 0, this.bitrate_stereoMode_Hist = re([16, 4 + 1]), this.bitrate_blockType_Hist = re([16, 4 + 1 + 1]), this.pinfo = null, this.hip = null, this.in_buffer_nsamples = 0, this.in_buffer_0 = null, this.in_buffer_1 = null, this.iteration_loop = null;
  for (var X = 0; X < this.en.length; X++)
    this.en[X] = new je();
  for (var X = 0; X < this.thm.length; X++)
    this.thm[X] = new je();
  for (var X = 0; X < this.header.length; X++)
    this.header[X] = new Z();
}
var ne = E1, A2 = Q0, H1 = A2.new_float, V1 = t1();
function R2() {
  this.useAdjust = 0, this.aaSensitivityP = 0, this.adjust = 0, this.adjustLimit = 0, this.decay = 0, this.floor = 0, this.l = H1(V1.SBMAX_l), this.s = H1(V1.SBMAX_s), this.psfb21 = H1(V1.PSFB21), this.psfb12 = H1(V1.PSFB12), this.cb_l = H1(V1.CBANDS), this.cb_s = H1(V1.CBANDS), this.eql_w = H1(V1.BLKSIZE / 2);
}
var x2 = R2, La = Q0, _1 = La.System, ze = La.Arrays;
j0.STEPS_per_dB = 100;
j0.MAX_dB = 120;
j0.GAIN_NOT_ENOUGH_SAMPLES = -24601;
j0.GAIN_ANALYSIS_ERROR = 0;
j0.GAIN_ANALYSIS_OK = 1;
j0.INIT_GAIN_ANALYSIS_ERROR = 0;
j0.INIT_GAIN_ANALYSIS_OK = 1;
j0.YULE_ORDER = 10;
j0.MAX_ORDER = j0.YULE_ORDER;
j0.MAX_SAMP_FREQ = 48e3;
j0.RMS_WINDOW_TIME_NUMERATOR = 1;
j0.RMS_WINDOW_TIME_DENOMINATOR = 20;
j0.MAX_SAMPLES_PER_WINDOW = j0.MAX_SAMP_FREQ * j0.RMS_WINDOW_TIME_NUMERATOR / j0.RMS_WINDOW_TIME_DENOMINATOR + 1;
function j0() {
  var w = 64.82, Z = 0.95, X = j0.RMS_WINDOW_TIME_NUMERATOR, z = j0.RMS_WINDOW_TIME_DENOMINATOR, u0 = [
    [
      0.038575994352,
      -3.84664617118067,
      -0.02160367184185,
      7.81501653005538,
      -0.00123395316851,
      -11.34170355132042,
      -9291677959e-14,
      13.05504219327545,
      -0.01655260341619,
      -12.28759895145294,
      0.02161526843274,
      9.4829380631979,
      -0.02074045215285,
      -5.87257861775999,
      0.00594298065125,
      2.75465861874613,
      0.00306428023191,
      -0.86984376593551,
      12025322027e-14,
      0.13919314567432,
      0.00288463683916
    ],
    [
      0.0541865640643,
      -3.47845948550071,
      -0.02911007808948,
      6.36317777566148,
      -0.00848709379851,
      -8.54751527471874,
      -0.00851165645469,
      9.4769360780128,
      -0.00834990904936,
      -8.81498681370155,
      0.02245293253339,
      6.85401540936998,
      -0.02596338512915,
      -4.39470996079559,
      0.01624864962975,
      2.19611684890774,
      -0.00240879051584,
      -0.75104302451432,
      0.00674613682247,
      0.13149317958808,
      -0.00187763777362
    ],
    [
      0.15457299681924,
      -2.37898834973084,
      -0.09331049056315,
      2.84868151156327,
      -0.06247880153653,
      -2.64577170229825,
      0.02163541888798,
      2.23697657451713,
      -0.05588393329856,
      -1.67148153367602,
      0.04781476674921,
      1.00595954808547,
      0.00222312597743,
      -0.45953458054983,
      0.03174092540049,
      0.16378164858596,
      -0.01390589421898,
      -0.05032077717131,
      0.00651420667831,
      0.0234789740702,
      -0.00881362733839
    ],
    [
      0.30296907319327,
      -1.61273165137247,
      -0.22613988682123,
      1.0797749225997,
      -0.08587323730772,
      -0.2565625775407,
      0.03282930172664,
      -0.1627671912044,
      -0.00915702933434,
      -0.22638893773906,
      -0.02364141202522,
      0.39120800788284,
      -0.00584456039913,
      -0.22138138954925,
      0.06276101321749,
      0.04500235387352,
      -828086748e-14,
      0.02005851806501,
      0.00205861885564,
      0.00302439095741,
      -0.02950134983287
    ],
    [
      0.33642304856132,
      -1.49858979367799,
      -0.2557224142557,
      0.87350271418188,
      -0.11828570177555,
      0.12205022308084,
      0.11921148675203,
      -0.80774944671438,
      -0.07834489609479,
      0.47854794562326,
      -0.0046997791438,
      -0.12453458140019,
      -0.0058950022444,
      -0.04067510197014,
      0.05724228140351,
      0.08333755284107,
      0.00832043980773,
      -0.04237348025746,
      -0.0163538138454,
      0.02977207319925,
      -0.0176017656815
    ],
    [
      0.4491525660845,
      -0.62820619233671,
      -0.14351757464547,
      0.29661783706366,
      -0.22784394429749,
      -0.372563729424,
      -0.01419140100551,
      0.00213767857124,
      0.04078262797139,
      -0.42029820170918,
      -0.12398163381748,
      0.22199650564824,
      0.04097565135648,
      0.00613424350682,
      0.10478503600251,
      0.06747620744683,
      -0.01863887810927,
      0.05784820375801,
      -0.03193428438915,
      0.03222754072173,
      0.00541907748707
    ],
    [
      0.56619470757641,
      -1.04800335126349,
      -0.75464456939302,
      0.29156311971249,
      0.1624213774223,
      -0.26806001042947,
      0.16744243493672,
      0.00819999645858,
      -0.18901604199609,
      0.45054734505008,
      0.3093178284183,
      -0.33032403314006,
      -0.27562961986224,
      0.0673936833311,
      0.00647310677246,
      -0.04784254229033,
      0.08647503780351,
      0.01639907836189,
      -0.0378898455484,
      0.01807364323573,
      -0.00588215443421
    ],
    [
      0.58100494960553,
      -0.51035327095184,
      -0.53174909058578,
      -0.31863563325245,
      -0.14289799034253,
      -0.20256413484477,
      0.17520704835522,
      0.1472815413433,
      0.02377945217615,
      0.38952639978999,
      0.15558449135573,
      -0.23313271880868,
      -0.25344790059353,
      -0.05246019024463,
      0.01628462406333,
      -0.02505961724053,
      0.06920467763959,
      0.02442357316099,
      -0.03721611395801,
      0.01818801111503,
      -0.00749618797172
    ],
    [
      0.53648789255105,
      -0.2504987195602,
      -0.42163034350696,
      -0.43193942311114,
      -0.00275953611929,
      -0.03424681017675,
      0.04267842219415,
      -0.04678328784242,
      -0.10214864179676,
      0.26408300200955,
      0.14590772289388,
      0.15113130533216,
      -0.02459864859345,
      -0.17556493366449,
      -0.11202315195388,
      -0.18823009262115,
      -0.04060034127,
      0.05477720428674,
      0.0478866554818,
      0.0470440968812,
      -0.02217936801134
    ]
  ], W = [
    [
      0.98621192462708,
      -1.97223372919527,
      -1.97242384925416,
      0.97261396931306,
      0.98621192462708
    ],
    [
      0.98500175787242,
      -1.96977855582618,
      -1.97000351574484,
      0.9702284756635,
      0.98500175787242
    ],
    [
      0.97938932735214,
      -1.95835380975398,
      -1.95877865470428,
      0.95920349965459,
      0.97938932735214
    ],
    [
      0.97531843204928,
      -1.95002759149878,
      -1.95063686409857,
      0.95124613669835,
      0.97531843204928
    ],
    [
      0.97316523498161,
      -1.94561023566527,
      -1.94633046996323,
      0.94705070426118,
      0.97316523498161
    ],
    [
      0.96454515552826,
      -1.92783286977036,
      -1.92909031105652,
      0.93034775234268,
      0.96454515552826
    ],
    [
      0.96009142950541,
      -1.91858953033784,
      -1.92018285901082,
      0.92177618768381,
      0.96009142950541
    ],
    [
      0.95856916599601,
      -1.9154210807478,
      -1.91713833199203,
      0.91885558323625,
      0.95856916599601
    ],
    [
      0.94597685600279,
      -1.88903307939452,
      -1.89195371200558,
      0.89487434461664,
      0.94597685600279
    ]
  ];
  function Q(m, O, s0, K, t0, U) {
    for (; t0-- != 0; )
      s0[K] = 1e-10 + m[O + 0] * U[0] - s0[K - 1] * U[1] + m[O - 1] * U[2] - s0[K - 2] * U[3] + m[O - 2] * U[4] - s0[K - 3] * U[5] + m[O - 3] * U[6] - s0[K - 4] * U[7] + m[O - 4] * U[8] - s0[K - 5] * U[9] + m[O - 5] * U[10] - s0[K - 6] * U[11] + m[O - 6] * U[12] - s0[K - 7] * U[13] + m[O - 7] * U[14] - s0[K - 8] * U[15] + m[O - 8] * U[16] - s0[K - 9] * U[17] + m[O - 9] * U[18] - s0[K - 10] * U[19] + m[O - 10] * U[20], ++K, ++O;
  }
  function D(m, O, s0, K, t0, U) {
    for (; t0-- != 0; )
      s0[K] = m[O + 0] * U[0] - s0[K - 1] * U[1] + m[O - 1] * U[2] - s0[K - 2] * U[3] + m[O - 2] * U[4], ++K, ++O;
  }
  function g(m, O) {
    for (var s0 = 0; s0 < MAX_ORDER; s0++)
      m.linprebuf[s0] = m.lstepbuf[s0] = m.loutbuf[s0] = m.rinprebuf[s0] = m.rstepbuf[s0] = m.routbuf[s0] = 0;
    switch (0 | O) {
      case 48e3:
        m.reqindex = 0;
        break;
      case 44100:
        m.reqindex = 1;
        break;
      case 32e3:
        m.reqindex = 2;
        break;
      case 24e3:
        m.reqindex = 3;
        break;
      case 22050:
        m.reqindex = 4;
        break;
      case 16e3:
        m.reqindex = 5;
        break;
      case 12e3:
        m.reqindex = 6;
        break;
      case 11025:
        m.reqindex = 7;
        break;
      case 8e3:
        m.reqindex = 8;
        break;
      default:
        return INIT_GAIN_ANALYSIS_ERROR;
    }
    return m.sampleWindow = 0 | (O * X + z - 1) / z, m.lsum = 0, m.rsum = 0, m.totsamp = 0, ze.ill(m.A, 0), INIT_GAIN_ANALYSIS_OK;
  }
  this.InitGainAnalysis = function(m, O) {
    return g(m, O) != INIT_GAIN_ANALYSIS_OK ? INIT_GAIN_ANALYSIS_ERROR : (m.linpre = MAX_ORDER, m.rinpre = MAX_ORDER, m.lstep = MAX_ORDER, m.rstep = MAX_ORDER, m.lout = MAX_ORDER, m.rout = MAX_ORDER, ze.fill(m.B, 0), INIT_GAIN_ANALYSIS_OK);
  };
  function f0(m) {
    return m * m;
  }
  this.AnalyzeSamples = function(m, O, s0, K, t0, U, R) {
    var o, u, d, e, l, M, p;
    if (U == 0)
      return GAIN_ANALYSIS_OK;
    switch (p = 0, l = U, R) {
      case 1:
        K = O, t0 = s0;
        break;
      case 2:
        break;
      default:
        return GAIN_ANALYSIS_ERROR;
    }
    for (U < MAX_ORDER ? (_1.arraycopy(
      O,
      s0,
      m.linprebuf,
      MAX_ORDER,
      U
    ), _1.arraycopy(
      K,
      t0,
      m.rinprebuf,
      MAX_ORDER,
      U
    )) : (_1.arraycopy(
      O,
      s0,
      m.linprebuf,
      MAX_ORDER,
      MAX_ORDER
    ), _1.arraycopy(
      K,
      t0,
      m.rinprebuf,
      MAX_ORDER,
      MAX_ORDER
    )); l > 0; ) {
      M = l > m.sampleWindow - m.totsamp ? m.sampleWindow - m.totsamp : l, p < MAX_ORDER ? (o = m.linpre + p, u = m.linprebuf, d = m.rinpre + p, e = m.rinprebuf, M > MAX_ORDER - p && (M = MAX_ORDER - p)) : (o = s0 + p, u = O, d = t0 + p, e = K), Q(u, o, m.lstepbuf, m.lstep + m.totsamp, M, u0[m.reqindex]), Q(e, d, m.rstepbuf, m.rstep + m.totsamp, M, u0[m.reqindex]), D(
        m.lstepbuf,
        m.lstep + m.totsamp,
        m.loutbuf,
        m.lout + m.totsamp,
        M,
        W[m.reqindex]
      ), D(
        m.rstepbuf,
        m.rstep + m.totsamp,
        m.routbuf,
        m.rout + m.totsamp,
        M,
        W[m.reqindex]
      ), o = m.lout + m.totsamp, u = m.loutbuf, d = m.rout + m.totsamp, e = m.routbuf;
      for (var H = M % 8; H-- != 0; )
        m.lsum += f0(u[o++]), m.rsum += f0(e[d++]);
      for (H = M / 8; H-- != 0; )
        m.lsum += f0(u[o + 0]) + f0(u[o + 1]) + f0(u[o + 2]) + f0(u[o + 3]) + f0(u[o + 4]) + f0(u[o + 5]) + f0(u[o + 6]) + f0(u[o + 7]), o += 8, m.rsum += f0(e[d + 0]) + f0(e[d + 1]) + f0(e[d + 2]) + f0(e[d + 3]) + f0(e[d + 4]) + f0(e[d + 5]) + f0(e[d + 6]) + f0(e[d + 7]), d += 8;
      if (l -= M, p += M, m.totsamp += M, m.totsamp == m.sampleWindow) {
        var B = j0.STEPS_per_dB * 10 * Math.log10((m.lsum + m.rsum) / m.totsamp * 0.5 + 1e-37), I = B <= 0 ? 0 : 0 | B;
        I >= m.A.length && (I = m.A.length - 1), m.A[I]++, m.lsum = m.rsum = 0, _1.arraycopy(
          m.loutbuf,
          m.totsamp,
          m.loutbuf,
          0,
          MAX_ORDER
        ), _1.arraycopy(
          m.routbuf,
          m.totsamp,
          m.routbuf,
          0,
          MAX_ORDER
        ), _1.arraycopy(
          m.lstepbuf,
          m.totsamp,
          m.lstepbuf,
          0,
          MAX_ORDER
        ), _1.arraycopy(
          m.rstepbuf,
          m.totsamp,
          m.rstepbuf,
          0,
          MAX_ORDER
        ), m.totsamp = 0;
      }
      if (m.totsamp > m.sampleWindow)
        return GAIN_ANALYSIS_ERROR;
    }
    return U < MAX_ORDER ? (_1.arraycopy(
      m.linprebuf,
      U,
      m.linprebuf,
      0,
      MAX_ORDER - U
    ), _1.arraycopy(
      m.rinprebuf,
      U,
      m.rinprebuf,
      0,
      MAX_ORDER - U
    ), _1.arraycopy(
      O,
      s0,
      m.linprebuf,
      MAX_ORDER - U,
      U
    ), _1.arraycopy(
      K,
      t0,
      m.rinprebuf,
      MAX_ORDER - U,
      U
    )) : (_1.arraycopy(O, s0 + U - MAX_ORDER, m.linprebuf, 0, MAX_ORDER), _1.arraycopy(K, t0 + U - MAX_ORDER, m.rinprebuf, 0, MAX_ORDER)), GAIN_ANALYSIS_OK;
  };
  function A(m, O) {
    var s0, K = 0;
    for (s0 = 0; s0 < O; s0++)
      K += m[s0];
    if (K == 0)
      return GAIN_NOT_ENOUGH_SAMPLES;
    var t0 = 0 | Math.ceil(K * (1 - Z));
    for (s0 = O; s0-- > 0 && !((t0 -= m[s0]) <= 0); )
      ;
    return w - s0 / j0.STEPS_per_dB;
  }
  this.GetTitleGain = function(m) {
    for (var O = A(m.A, m.A.length), s0 = 0; s0 < m.A.length; s0++)
      m.B[s0] += m.A[s0], m.A[s0] = 0;
    for (var s0 = 0; s0 < MAX_ORDER; s0++)
      m.linprebuf[s0] = m.lstepbuf[s0] = m.loutbuf[s0] = m.rinprebuf[s0] = m.rstepbuf[s0] = m.routbuf[s0] = 0;
    return m.totsamp = 0, m.lsum = m.rsum = 0, O;
  };
}
var Na = j0, pa = Q0, k1 = pa.new_float, Je = pa.new_int, l1 = Na;
function M2() {
  this.linprebuf = k1(l1.MAX_ORDER * 2), this.linpre = 0, this.lstepbuf = k1(l1.MAX_SAMPLES_PER_WINDOW + l1.MAX_ORDER), this.lstep = 0, this.loutbuf = k1(l1.MAX_SAMPLES_PER_WINDOW + l1.MAX_ORDER), this.lout = 0, this.rinprebuf = k1(l1.MAX_ORDER * 2), this.rinpre = 0, this.rstepbuf = k1(l1.MAX_SAMPLES_PER_WINDOW + l1.MAX_ORDER), this.rstep = 0, this.routbuf = k1(l1.MAX_SAMPLES_PER_WINDOW + l1.MAX_ORDER), this.rout = 0, this.sampleWindow = 0, this.totsamp = 0, this.lsum = 0, this.rsum = 0, this.freqindex = 0, this.first = 0, this.A = Je(0 | l1.STEPS_per_dB * l1.MAX_dB), this.B = Je(0 | l1.STEPS_per_dB * l1.MAX_dB);
}
var E2 = M2;
function B2(w) {
  this.bits = w;
}
var Ha = B2, pe = Q0, ge = pe.new_float, T2 = pe.new_int, ea = pe.assert, y2 = Ha, aa = t1(), w2 = ie, I2 = ne;
function L2(w) {
  var Z = w;
  this.quantize = Z, this.iteration_loop = function(X, z, u0, W) {
    var Q = X.internal_flags, D = ge(w2.SFBMAX), g = ge(576), f0 = T2(2), A = 0, m, O = Q.l3_side, s0 = new y2(A);
    this.quantize.rv.ResvFrameBegin(X, s0), A = s0.bits;
    for (var K = 0; K < Q.mode_gr; K++) {
      m = this.quantize.qupvt.on_pe(
        X,
        z,
        f0,
        A,
        K,
        K
      ), Q.mode_ext == aa.MPG_MD_MS_LR && (this.quantize.ms_convert(Q.l3_side, K), this.quantize.qupvt.reduce_side(
        f0,
        u0[K],
        A,
        m
      ));
      for (var t0 = 0; t0 < Q.channels_out; t0++) {
        var U, R, o = O.tt[K][t0];
        o.block_type != aa.SHORT_TYPE ? (U = 0, R = Q.PSY.mask_adjust - U) : (U = 0, R = Q.PSY.mask_adjust_short - U), Q.masking_lower = Math.pow(
          10,
          R * 0.1
        ), this.quantize.init_outer_loop(Q, o), this.quantize.init_xrpow(Q, o, g) && (this.quantize.qupvt.calc_xmin(
          X,
          W[K][t0],
          o,
          D
        ), this.quantize.outer_loop(
          X,
          o,
          D,
          g,
          t0,
          f0[t0]
        )), this.quantize.iteration_finish_one(Q, K, t0), ea(o.part2_3_length <= I2.MAX_BITS_PER_CHANNEL), ea(o.part2_3_length <= f0[t0]);
      }
    }
    this.quantize.rv.ResvFrameEnd(Q, A);
  };
}
var N2 = L2;
function q0(w, Z, X, z) {
  this.xlen = w, this.linmax = Z, this.table = X, this.hlen = z;
}
var o0 = {};
o0.t1HB = [
  1,
  1,
  1,
  0
];
o0.t2HB = [
  1,
  2,
  1,
  3,
  1,
  1,
  3,
  2,
  0
];
o0.t3HB = [
  3,
  2,
  1,
  1,
  1,
  1,
  3,
  2,
  0
];
o0.t5HB = [
  1,
  2,
  6,
  5,
  3,
  1,
  4,
  4,
  7,
  5,
  7,
  1,
  6,
  1,
  1,
  0
];
o0.t6HB = [
  7,
  3,
  5,
  1,
  6,
  2,
  3,
  2,
  5,
  4,
  4,
  1,
  3,
  3,
  2,
  0
];
o0.t7HB = [
  1,
  2,
  10,
  19,
  16,
  10,
  3,
  3,
  7,
  10,
  5,
  3,
  11,
  4,
  13,
  17,
  8,
  4,
  12,
  11,
  18,
  15,
  11,
  2,
  7,
  6,
  9,
  14,
  3,
  1,
  6,
  4,
  5,
  3,
  2,
  0
];
o0.t8HB = [
  3,
  4,
  6,
  18,
  12,
  5,
  5,
  1,
  2,
  16,
  9,
  3,
  7,
  3,
  5,
  14,
  7,
  3,
  19,
  17,
  15,
  13,
  10,
  4,
  13,
  5,
  8,
  11,
  5,
  1,
  12,
  4,
  4,
  1,
  1,
  0
];
o0.t9HB = [
  7,
  5,
  9,
  14,
  15,
  7,
  6,
  4,
  5,
  5,
  6,
  7,
  7,
  6,
  8,
  8,
  8,
  5,
  15,
  6,
  9,
  10,
  5,
  1,
  11,
  7,
  9,
  6,
  4,
  1,
  14,
  4,
  6,
  2,
  6,
  0
];
o0.t10HB = [
  1,
  2,
  10,
  23,
  35,
  30,
  12,
  17,
  3,
  3,
  8,
  12,
  18,
  21,
  12,
  7,
  11,
  9,
  15,
  21,
  32,
  40,
  19,
  6,
  14,
  13,
  22,
  34,
  46,
  23,
  18,
  7,
  20,
  19,
  33,
  47,
  27,
  22,
  9,
  3,
  31,
  22,
  41,
  26,
  21,
  20,
  5,
  3,
  14,
  13,
  10,
  11,
  16,
  6,
  5,
  1,
  9,
  8,
  7,
  8,
  4,
  4,
  2,
  0
];
o0.t11HB = [
  3,
  4,
  10,
  24,
  34,
  33,
  21,
  15,
  5,
  3,
  4,
  10,
  32,
  17,
  11,
  10,
  11,
  7,
  13,
  18,
  30,
  31,
  20,
  5,
  25,
  11,
  19,
  59,
  27,
  18,
  12,
  5,
  35,
  33,
  31,
  58,
  30,
  16,
  7,
  5,
  28,
  26,
  32,
  19,
  17,
  15,
  8,
  14,
  14,
  12,
  9,
  13,
  14,
  9,
  4,
  1,
  11,
  4,
  6,
  6,
  6,
  3,
  2,
  0
];
o0.t12HB = [
  9,
  6,
  16,
  33,
  41,
  39,
  38,
  26,
  7,
  5,
  6,
  9,
  23,
  16,
  26,
  11,
  17,
  7,
  11,
  14,
  21,
  30,
  10,
  7,
  17,
  10,
  15,
  12,
  18,
  28,
  14,
  5,
  32,
  13,
  22,
  19,
  18,
  16,
  9,
  5,
  40,
  17,
  31,
  29,
  17,
  13,
  4,
  2,
  27,
  12,
  11,
  15,
  10,
  7,
  4,
  1,
  27,
  12,
  8,
  12,
  6,
  3,
  1,
  0
];
o0.t13HB = [
  1,
  5,
  14,
  21,
  34,
  51,
  46,
  71,
  42,
  52,
  68,
  52,
  67,
  44,
  43,
  19,
  3,
  4,
  12,
  19,
  31,
  26,
  44,
  33,
  31,
  24,
  32,
  24,
  31,
  35,
  22,
  14,
  15,
  13,
  23,
  36,
  59,
  49,
  77,
  65,
  29,
  40,
  30,
  40,
  27,
  33,
  42,
  16,
  22,
  20,
  37,
  61,
  56,
  79,
  73,
  64,
  43,
  76,
  56,
  37,
  26,
  31,
  25,
  14,
  35,
  16,
  60,
  57,
  97,
  75,
  114,
  91,
  54,
  73,
  55,
  41,
  48,
  53,
  23,
  24,
  58,
  27,
  50,
  96,
  76,
  70,
  93,
  84,
  77,
  58,
  79,
  29,
  74,
  49,
  41,
  17,
  47,
  45,
  78,
  74,
  115,
  94,
  90,
  79,
  69,
  83,
  71,
  50,
  59,
  38,
  36,
  15,
  72,
  34,
  56,
  95,
  92,
  85,
  91,
  90,
  86,
  73,
  77,
  65,
  51,
  44,
  43,
  42,
  43,
  20,
  30,
  44,
  55,
  78,
  72,
  87,
  78,
  61,
  46,
  54,
  37,
  30,
  20,
  16,
  53,
  25,
  41,
  37,
  44,
  59,
  54,
  81,
  66,
  76,
  57,
  54,
  37,
  18,
  39,
  11,
  35,
  33,
  31,
  57,
  42,
  82,
  72,
  80,
  47,
  58,
  55,
  21,
  22,
  26,
  38,
  22,
  53,
  25,
  23,
  38,
  70,
  60,
  51,
  36,
  55,
  26,
  34,
  23,
  27,
  14,
  9,
  7,
  34,
  32,
  28,
  39,
  49,
  75,
  30,
  52,
  48,
  40,
  52,
  28,
  18,
  17,
  9,
  5,
  45,
  21,
  34,
  64,
  56,
  50,
  49,
  45,
  31,
  19,
  12,
  15,
  10,
  7,
  6,
  3,
  48,
  23,
  20,
  39,
  36,
  35,
  53,
  21,
  16,
  23,
  13,
  10,
  6,
  1,
  4,
  2,
  16,
  15,
  17,
  27,
  25,
  20,
  29,
  11,
  17,
  12,
  16,
  8,
  1,
  1,
  0,
  1
];
o0.t15HB = [
  7,
  12,
  18,
  53,
  47,
  76,
  124,
  108,
  89,
  123,
  108,
  119,
  107,
  81,
  122,
  63,
  13,
  5,
  16,
  27,
  46,
  36,
  61,
  51,
  42,
  70,
  52,
  83,
  65,
  41,
  59,
  36,
  19,
  17,
  15,
  24,
  41,
  34,
  59,
  48,
  40,
  64,
  50,
  78,
  62,
  80,
  56,
  33,
  29,
  28,
  25,
  43,
  39,
  63,
  55,
  93,
  76,
  59,
  93,
  72,
  54,
  75,
  50,
  29,
  52,
  22,
  42,
  40,
  67,
  57,
  95,
  79,
  72,
  57,
  89,
  69,
  49,
  66,
  46,
  27,
  77,
  37,
  35,
  66,
  58,
  52,
  91,
  74,
  62,
  48,
  79,
  63,
  90,
  62,
  40,
  38,
  125,
  32,
  60,
  56,
  50,
  92,
  78,
  65,
  55,
  87,
  71,
  51,
  73,
  51,
  70,
  30,
  109,
  53,
  49,
  94,
  88,
  75,
  66,
  122,
  91,
  73,
  56,
  42,
  64,
  44,
  21,
  25,
  90,
  43,
  41,
  77,
  73,
  63,
  56,
  92,
  77,
  66,
  47,
  67,
  48,
  53,
  36,
  20,
  71,
  34,
  67,
  60,
  58,
  49,
  88,
  76,
  67,
  106,
  71,
  54,
  38,
  39,
  23,
  15,
  109,
  53,
  51,
  47,
  90,
  82,
  58,
  57,
  48,
  72,
  57,
  41,
  23,
  27,
  62,
  9,
  86,
  42,
  40,
  37,
  70,
  64,
  52,
  43,
  70,
  55,
  42,
  25,
  29,
  18,
  11,
  11,
  118,
  68,
  30,
  55,
  50,
  46,
  74,
  65,
  49,
  39,
  24,
  16,
  22,
  13,
  14,
  7,
  91,
  44,
  39,
  38,
  34,
  63,
  52,
  45,
  31,
  52,
  28,
  19,
  14,
  8,
  9,
  3,
  123,
  60,
  58,
  53,
  47,
  43,
  32,
  22,
  37,
  24,
  17,
  12,
  15,
  10,
  2,
  1,
  71,
  37,
  34,
  30,
  28,
  20,
  17,
  26,
  21,
  16,
  10,
  6,
  8,
  6,
  2,
  0
];
o0.t16HB = [
  1,
  5,
  14,
  44,
  74,
  63,
  110,
  93,
  172,
  149,
  138,
  242,
  225,
  195,
  376,
  17,
  3,
  4,
  12,
  20,
  35,
  62,
  53,
  47,
  83,
  75,
  68,
  119,
  201,
  107,
  207,
  9,
  15,
  13,
  23,
  38,
  67,
  58,
  103,
  90,
  161,
  72,
  127,
  117,
  110,
  209,
  206,
  16,
  45,
  21,
  39,
  69,
  64,
  114,
  99,
  87,
  158,
  140,
  252,
  212,
  199,
  387,
  365,
  26,
  75,
  36,
  68,
  65,
  115,
  101,
  179,
  164,
  155,
  264,
  246,
  226,
  395,
  382,
  362,
  9,
  66,
  30,
  59,
  56,
  102,
  185,
  173,
  265,
  142,
  253,
  232,
  400,
  388,
  378,
  445,
  16,
  111,
  54,
  52,
  100,
  184,
  178,
  160,
  133,
  257,
  244,
  228,
  217,
  385,
  366,
  715,
  10,
  98,
  48,
  91,
  88,
  165,
  157,
  148,
  261,
  248,
  407,
  397,
  372,
  380,
  889,
  884,
  8,
  85,
  84,
  81,
  159,
  156,
  143,
  260,
  249,
  427,
  401,
  392,
  383,
  727,
  713,
  708,
  7,
  154,
  76,
  73,
  141,
  131,
  256,
  245,
  426,
  406,
  394,
  384,
  735,
  359,
  710,
  352,
  11,
  139,
  129,
  67,
  125,
  247,
  233,
  229,
  219,
  393,
  743,
  737,
  720,
  885,
  882,
  439,
  4,
  243,
  120,
  118,
  115,
  227,
  223,
  396,
  746,
  742,
  736,
  721,
  712,
  706,
  223,
  436,
  6,
  202,
  224,
  222,
  218,
  216,
  389,
  386,
  381,
  364,
  888,
  443,
  707,
  440,
  437,
  1728,
  4,
  747,
  211,
  210,
  208,
  370,
  379,
  734,
  723,
  714,
  1735,
  883,
  877,
  876,
  3459,
  865,
  2,
  377,
  369,
  102,
  187,
  726,
  722,
  358,
  711,
  709,
  866,
  1734,
  871,
  3458,
  870,
  434,
  0,
  12,
  10,
  7,
  11,
  10,
  17,
  11,
  9,
  13,
  12,
  10,
  7,
  5,
  3,
  1,
  3
];
o0.t24HB = [
  15,
  13,
  46,
  80,
  146,
  262,
  248,
  434,
  426,
  669,
  653,
  649,
  621,
  517,
  1032,
  88,
  14,
  12,
  21,
  38,
  71,
  130,
  122,
  216,
  209,
  198,
  327,
  345,
  319,
  297,
  279,
  42,
  47,
  22,
  41,
  74,
  68,
  128,
  120,
  221,
  207,
  194,
  182,
  340,
  315,
  295,
  541,
  18,
  81,
  39,
  75,
  70,
  134,
  125,
  116,
  220,
  204,
  190,
  178,
  325,
  311,
  293,
  271,
  16,
  147,
  72,
  69,
  135,
  127,
  118,
  112,
  210,
  200,
  188,
  352,
  323,
  306,
  285,
  540,
  14,
  263,
  66,
  129,
  126,
  119,
  114,
  214,
  202,
  192,
  180,
  341,
  317,
  301,
  281,
  262,
  12,
  249,
  123,
  121,
  117,
  113,
  215,
  206,
  195,
  185,
  347,
  330,
  308,
  291,
  272,
  520,
  10,
  435,
  115,
  111,
  109,
  211,
  203,
  196,
  187,
  353,
  332,
  313,
  298,
  283,
  531,
  381,
  17,
  427,
  212,
  208,
  205,
  201,
  193,
  186,
  177,
  169,
  320,
  303,
  286,
  268,
  514,
  377,
  16,
  335,
  199,
  197,
  191,
  189,
  181,
  174,
  333,
  321,
  305,
  289,
  275,
  521,
  379,
  371,
  11,
  668,
  184,
  183,
  179,
  175,
  344,
  331,
  314,
  304,
  290,
  277,
  530,
  383,
  373,
  366,
  10,
  652,
  346,
  171,
  168,
  164,
  318,
  309,
  299,
  287,
  276,
  263,
  513,
  375,
  368,
  362,
  6,
  648,
  322,
  316,
  312,
  307,
  302,
  292,
  284,
  269,
  261,
  512,
  376,
  370,
  364,
  359,
  4,
  620,
  300,
  296,
  294,
  288,
  282,
  273,
  266,
  515,
  380,
  374,
  369,
  365,
  361,
  357,
  2,
  1033,
  280,
  278,
  274,
  267,
  264,
  259,
  382,
  378,
  372,
  367,
  363,
  360,
  358,
  356,
  0,
  43,
  20,
  19,
  17,
  15,
  13,
  11,
  9,
  7,
  6,
  4,
  7,
  5,
  3,
  1,
  3
];
o0.t32HB = [
  1,
  10,
  8,
  20,
  12,
  20,
  16,
  32,
  14,
  12,
  24,
  0,
  28,
  16,
  24,
  16
];
o0.t33HB = [
  15,
  28,
  26,
  48,
  22,
  40,
  36,
  64,
  14,
  24,
  20,
  32,
  12,
  16,
  8,
  0
];
o0.t1l = [
  1,
  4,
  3,
  5
];
o0.t2l = [
  1,
  4,
  7,
  4,
  5,
  7,
  6,
  7,
  8
];
o0.t3l = [
  2,
  3,
  7,
  4,
  4,
  7,
  6,
  7,
  8
];
o0.t5l = [
  1,
  4,
  7,
  8,
  4,
  5,
  8,
  9,
  7,
  8,
  9,
  10,
  8,
  8,
  9,
  10
];
o0.t6l = [
  3,
  4,
  6,
  8,
  4,
  4,
  6,
  7,
  5,
  6,
  7,
  8,
  7,
  7,
  8,
  9
];
o0.t7l = [
  1,
  4,
  7,
  9,
  9,
  10,
  4,
  6,
  8,
  9,
  9,
  10,
  7,
  7,
  9,
  10,
  10,
  11,
  8,
  9,
  10,
  11,
  11,
  11,
  8,
  9,
  10,
  11,
  11,
  12,
  9,
  10,
  11,
  12,
  12,
  12
];
o0.t8l = [
  2,
  4,
  7,
  9,
  9,
  10,
  4,
  4,
  6,
  10,
  10,
  10,
  7,
  6,
  8,
  10,
  10,
  11,
  9,
  10,
  10,
  11,
  11,
  12,
  9,
  9,
  10,
  11,
  12,
  12,
  10,
  10,
  11,
  11,
  13,
  13
];
o0.t9l = [
  3,
  4,
  6,
  7,
  9,
  10,
  4,
  5,
  6,
  7,
  8,
  10,
  5,
  6,
  7,
  8,
  9,
  10,
  7,
  7,
  8,
  9,
  9,
  10,
  8,
  8,
  9,
  9,
  10,
  11,
  9,
  9,
  10,
  10,
  11,
  11
];
o0.t10l = [
  1,
  4,
  7,
  9,
  10,
  10,
  10,
  11,
  4,
  6,
  8,
  9,
  10,
  11,
  10,
  10,
  7,
  8,
  9,
  10,
  11,
  12,
  11,
  11,
  8,
  9,
  10,
  11,
  12,
  12,
  11,
  12,
  9,
  10,
  11,
  12,
  12,
  12,
  12,
  12,
  10,
  11,
  12,
  12,
  13,
  13,
  12,
  13,
  9,
  10,
  11,
  12,
  12,
  12,
  13,
  13,
  10,
  10,
  11,
  12,
  12,
  13,
  13,
  13
];
o0.t11l = [
  2,
  4,
  6,
  8,
  9,
  10,
  9,
  10,
  4,
  5,
  6,
  8,
  10,
  10,
  9,
  10,
  6,
  7,
  8,
  9,
  10,
  11,
  10,
  10,
  8,
  8,
  9,
  11,
  10,
  12,
  10,
  11,
  9,
  10,
  10,
  11,
  11,
  12,
  11,
  12,
  9,
  10,
  11,
  12,
  12,
  13,
  12,
  13,
  9,
  9,
  9,
  10,
  11,
  12,
  12,
  12,
  9,
  9,
  10,
  11,
  12,
  12,
  12,
  12
];
o0.t12l = [
  4,
  4,
  6,
  8,
  9,
  10,
  10,
  10,
  4,
  5,
  6,
  7,
  9,
  9,
  10,
  10,
  6,
  6,
  7,
  8,
  9,
  10,
  9,
  10,
  7,
  7,
  8,
  8,
  9,
  10,
  10,
  10,
  8,
  8,
  9,
  9,
  10,
  10,
  10,
  11,
  9,
  9,
  10,
  10,
  10,
  11,
  10,
  11,
  9,
  9,
  9,
  10,
  10,
  11,
  11,
  12,
  10,
  10,
  10,
  11,
  11,
  11,
  11,
  12
];
o0.t13l = [
  1,
  5,
  7,
  8,
  9,
  10,
  10,
  11,
  10,
  11,
  12,
  12,
  13,
  13,
  14,
  14,
  4,
  6,
  8,
  9,
  10,
  10,
  11,
  11,
  11,
  11,
  12,
  12,
  13,
  14,
  14,
  14,
  7,
  8,
  9,
  10,
  11,
  11,
  12,
  12,
  11,
  12,
  12,
  13,
  13,
  14,
  15,
  15,
  8,
  9,
  10,
  11,
  11,
  12,
  12,
  12,
  12,
  13,
  13,
  13,
  13,
  14,
  15,
  15,
  9,
  9,
  11,
  11,
  12,
  12,
  13,
  13,
  12,
  13,
  13,
  14,
  14,
  15,
  15,
  16,
  10,
  10,
  11,
  12,
  12,
  12,
  13,
  13,
  13,
  13,
  14,
  13,
  15,
  15,
  16,
  16,
  10,
  11,
  12,
  12,
  13,
  13,
  13,
  13,
  13,
  14,
  14,
  14,
  15,
  15,
  16,
  16,
  11,
  11,
  12,
  13,
  13,
  13,
  14,
  14,
  14,
  14,
  15,
  15,
  15,
  16,
  18,
  18,
  10,
  10,
  11,
  12,
  12,
  13,
  13,
  14,
  14,
  14,
  14,
  15,
  15,
  16,
  17,
  17,
  11,
  11,
  12,
  12,
  13,
  13,
  13,
  15,
  14,
  15,
  15,
  16,
  16,
  16,
  18,
  17,
  11,
  12,
  12,
  13,
  13,
  14,
  14,
  15,
  14,
  15,
  16,
  15,
  16,
  17,
  18,
  19,
  12,
  12,
  12,
  13,
  14,
  14,
  14,
  14,
  15,
  15,
  15,
  16,
  17,
  17,
  17,
  18,
  12,
  13,
  13,
  14,
  14,
  15,
  14,
  15,
  16,
  16,
  17,
  17,
  17,
  18,
  18,
  18,
  13,
  13,
  14,
  15,
  15,
  15,
  16,
  16,
  16,
  16,
  16,
  17,
  18,
  17,
  18,
  18,
  14,
  14,
  14,
  15,
  15,
  15,
  17,
  16,
  16,
  19,
  17,
  17,
  17,
  19,
  18,
  18,
  13,
  14,
  15,
  16,
  16,
  16,
  17,
  16,
  17,
  17,
  18,
  18,
  21,
  20,
  21,
  18
];
o0.t15l = [
  3,
  5,
  6,
  8,
  8,
  9,
  10,
  10,
  10,
  11,
  11,
  12,
  12,
  12,
  13,
  14,
  5,
  5,
  7,
  8,
  9,
  9,
  10,
  10,
  10,
  11,
  11,
  12,
  12,
  12,
  13,
  13,
  6,
  7,
  7,
  8,
  9,
  9,
  10,
  10,
  10,
  11,
  11,
  12,
  12,
  13,
  13,
  13,
  7,
  8,
  8,
  9,
  9,
  10,
  10,
  11,
  11,
  11,
  12,
  12,
  12,
  13,
  13,
  13,
  8,
  8,
  9,
  9,
  10,
  10,
  11,
  11,
  11,
  11,
  12,
  12,
  12,
  13,
  13,
  13,
  9,
  9,
  9,
  10,
  10,
  10,
  11,
  11,
  11,
  11,
  12,
  12,
  13,
  13,
  13,
  14,
  10,
  9,
  10,
  10,
  10,
  11,
  11,
  11,
  11,
  12,
  12,
  12,
  13,
  13,
  14,
  14,
  10,
  10,
  10,
  11,
  11,
  11,
  11,
  12,
  12,
  12,
  12,
  12,
  13,
  13,
  13,
  14,
  10,
  10,
  10,
  11,
  11,
  11,
  11,
  12,
  12,
  12,
  12,
  13,
  13,
  14,
  14,
  14,
  10,
  10,
  11,
  11,
  11,
  11,
  12,
  12,
  12,
  13,
  13,
  13,
  13,
  14,
  14,
  14,
  11,
  11,
  11,
  11,
  12,
  12,
  12,
  12,
  12,
  13,
  13,
  13,
  13,
  14,
  15,
  14,
  11,
  11,
  11,
  11,
  12,
  12,
  12,
  12,
  13,
  13,
  13,
  13,
  14,
  14,
  14,
  15,
  12,
  12,
  11,
  12,
  12,
  12,
  13,
  13,
  13,
  13,
  13,
  13,
  14,
  14,
  15,
  15,
  12,
  12,
  12,
  12,
  12,
  13,
  13,
  13,
  13,
  14,
  14,
  14,
  14,
  14,
  15,
  15,
  13,
  13,
  13,
  13,
  13,
  13,
  13,
  13,
  14,
  14,
  14,
  14,
  15,
  15,
  14,
  15,
  13,
  13,
  13,
  13,
  13,
  13,
  13,
  14,
  14,
  14,
  14,
  14,
  15,
  15,
  15,
  15
];
o0.t16_5l = [
  1,
  5,
  7,
  9,
  10,
  10,
  11,
  11,
  12,
  12,
  12,
  13,
  13,
  13,
  14,
  11,
  4,
  6,
  8,
  9,
  10,
  11,
  11,
  11,
  12,
  12,
  12,
  13,
  14,
  13,
  14,
  11,
  7,
  8,
  9,
  10,
  11,
  11,
  12,
  12,
  13,
  12,
  13,
  13,
  13,
  14,
  14,
  12,
  9,
  9,
  10,
  11,
  11,
  12,
  12,
  12,
  13,
  13,
  14,
  14,
  14,
  15,
  15,
  13,
  10,
  10,
  11,
  11,
  12,
  12,
  13,
  13,
  13,
  14,
  14,
  14,
  15,
  15,
  15,
  12,
  10,
  10,
  11,
  11,
  12,
  13,
  13,
  14,
  13,
  14,
  14,
  15,
  15,
  15,
  16,
  13,
  11,
  11,
  11,
  12,
  13,
  13,
  13,
  13,
  14,
  14,
  14,
  14,
  15,
  15,
  16,
  13,
  11,
  11,
  12,
  12,
  13,
  13,
  13,
  14,
  14,
  15,
  15,
  15,
  15,
  17,
  17,
  13,
  11,
  12,
  12,
  13,
  13,
  13,
  14,
  14,
  15,
  15,
  15,
  15,
  16,
  16,
  16,
  13,
  12,
  12,
  12,
  13,
  13,
  14,
  14,
  15,
  15,
  15,
  15,
  16,
  15,
  16,
  15,
  14,
  12,
  13,
  12,
  13,
  14,
  14,
  14,
  14,
  15,
  16,
  16,
  16,
  17,
  17,
  16,
  13,
  13,
  13,
  13,
  13,
  14,
  14,
  15,
  16,
  16,
  16,
  16,
  16,
  16,
  15,
  16,
  14,
  13,
  14,
  14,
  14,
  14,
  15,
  15,
  15,
  15,
  17,
  16,
  16,
  16,
  16,
  18,
  14,
  15,
  14,
  14,
  14,
  15,
  15,
  16,
  16,
  16,
  18,
  17,
  17,
  17,
  19,
  17,
  14,
  14,
  15,
  13,
  14,
  16,
  16,
  15,
  16,
  16,
  17,
  18,
  17,
  19,
  17,
  16,
  14,
  11,
  11,
  11,
  12,
  12,
  13,
  13,
  13,
  14,
  14,
  14,
  14,
  14,
  14,
  14,
  12
];
o0.t16l = [
  1,
  5,
  7,
  9,
  10,
  10,
  11,
  11,
  12,
  12,
  12,
  13,
  13,
  13,
  14,
  10,
  4,
  6,
  8,
  9,
  10,
  11,
  11,
  11,
  12,
  12,
  12,
  13,
  14,
  13,
  14,
  10,
  7,
  8,
  9,
  10,
  11,
  11,
  12,
  12,
  13,
  12,
  13,
  13,
  13,
  14,
  14,
  11,
  9,
  9,
  10,
  11,
  11,
  12,
  12,
  12,
  13,
  13,
  14,
  14,
  14,
  15,
  15,
  12,
  10,
  10,
  11,
  11,
  12,
  12,
  13,
  13,
  13,
  14,
  14,
  14,
  15,
  15,
  15,
  11,
  10,
  10,
  11,
  11,
  12,
  13,
  13,
  14,
  13,
  14,
  14,
  15,
  15,
  15,
  16,
  12,
  11,
  11,
  11,
  12,
  13,
  13,
  13,
  13,
  14,
  14,
  14,
  14,
  15,
  15,
  16,
  12,
  11,
  11,
  12,
  12,
  13,
  13,
  13,
  14,
  14,
  15,
  15,
  15,
  15,
  17,
  17,
  12,
  11,
  12,
  12,
  13,
  13,
  13,
  14,
  14,
  15,
  15,
  15,
  15,
  16,
  16,
  16,
  12,
  12,
  12,
  12,
  13,
  13,
  14,
  14,
  15,
  15,
  15,
  15,
  16,
  15,
  16,
  15,
  13,
  12,
  13,
  12,
  13,
  14,
  14,
  14,
  14,
  15,
  16,
  16,
  16,
  17,
  17,
  16,
  12,
  13,
  13,
  13,
  13,
  14,
  14,
  15,
  16,
  16,
  16,
  16,
  16,
  16,
  15,
  16,
  13,
  13,
  14,
  14,
  14,
  14,
  15,
  15,
  15,
  15,
  17,
  16,
  16,
  16,
  16,
  18,
  13,
  15,
  14,
  14,
  14,
  15,
  15,
  16,
  16,
  16,
  18,
  17,
  17,
  17,
  19,
  17,
  13,
  14,
  15,
  13,
  14,
  16,
  16,
  15,
  16,
  16,
  17,
  18,
  17,
  19,
  17,
  16,
  13,
  10,
  10,
  10,
  11,
  11,
  12,
  12,
  12,
  13,
  13,
  13,
  13,
  13,
  13,
  13,
  10
];
o0.t24l = [
  4,
  5,
  7,
  8,
  9,
  10,
  10,
  11,
  11,
  12,
  12,
  12,
  12,
  12,
  13,
  10,
  5,
  6,
  7,
  8,
  9,
  10,
  10,
  11,
  11,
  11,
  12,
  12,
  12,
  12,
  12,
  10,
  7,
  7,
  8,
  9,
  9,
  10,
  10,
  11,
  11,
  11,
  11,
  12,
  12,
  12,
  13,
  9,
  8,
  8,
  9,
  9,
  10,
  10,
  10,
  11,
  11,
  11,
  11,
  12,
  12,
  12,
  12,
  9,
  9,
  9,
  9,
  10,
  10,
  10,
  10,
  11,
  11,
  11,
  12,
  12,
  12,
  12,
  13,
  9,
  10,
  9,
  10,
  10,
  10,
  10,
  11,
  11,
  11,
  11,
  12,
  12,
  12,
  12,
  12,
  9,
  10,
  10,
  10,
  10,
  10,
  11,
  11,
  11,
  11,
  12,
  12,
  12,
  12,
  12,
  13,
  9,
  11,
  10,
  10,
  10,
  11,
  11,
  11,
  11,
  12,
  12,
  12,
  12,
  12,
  13,
  13,
  10,
  11,
  11,
  11,
  11,
  11,
  11,
  11,
  11,
  11,
  12,
  12,
  12,
  12,
  13,
  13,
  10,
  11,
  11,
  11,
  11,
  11,
  11,
  11,
  12,
  12,
  12,
  12,
  12,
  13,
  13,
  13,
  10,
  12,
  11,
  11,
  11,
  11,
  12,
  12,
  12,
  12,
  12,
  12,
  13,
  13,
  13,
  13,
  10,
  12,
  12,
  11,
  11,
  11,
  12,
  12,
  12,
  12,
  12,
  12,
  13,
  13,
  13,
  13,
  10,
  12,
  12,
  12,
  12,
  12,
  12,
  12,
  12,
  12,
  12,
  13,
  13,
  13,
  13,
  13,
  10,
  12,
  12,
  12,
  12,
  12,
  12,
  12,
  12,
  13,
  13,
  13,
  13,
  13,
  13,
  13,
  10,
  13,
  12,
  12,
  12,
  12,
  12,
  12,
  13,
  13,
  13,
  13,
  13,
  13,
  13,
  13,
  10,
  9,
  9,
  9,
  9,
  9,
  9,
  9,
  9,
  9,
  9,
  9,
  10,
  10,
  10,
  10,
  6
];
o0.t32l = [
  1 + 0,
  4 + 1,
  4 + 1,
  5 + 2,
  4 + 1,
  6 + 2,
  5 + 2,
  6 + 3,
  4 + 1,
  5 + 2,
  5 + 2,
  6 + 3,
  5 + 2,
  6 + 3,
  6 + 3,
  6 + 4
];
o0.t33l = [
  4 + 0,
  4 + 1,
  4 + 1,
  4 + 2,
  4 + 1,
  4 + 2,
  4 + 2,
  4 + 3,
  4 + 1,
  4 + 2,
  4 + 2,
  4 + 3,
  4 + 2,
  4 + 3,
  4 + 3,
  4 + 4
];
o0.ht = [
  /* xlen, linmax, table, hlen */
  new q0(0, 0, null, null),
  new q0(2, 0, o0.t1HB, o0.t1l),
  new q0(3, 0, o0.t2HB, o0.t2l),
  new q0(3, 0, o0.t3HB, o0.t3l),
  new q0(0, 0, null, null),
  /* Apparently not used */
  new q0(4, 0, o0.t5HB, o0.t5l),
  new q0(4, 0, o0.t6HB, o0.t6l),
  new q0(6, 0, o0.t7HB, o0.t7l),
  new q0(6, 0, o0.t8HB, o0.t8l),
  new q0(6, 0, o0.t9HB, o0.t9l),
  new q0(8, 0, o0.t10HB, o0.t10l),
  new q0(8, 0, o0.t11HB, o0.t11l),
  new q0(8, 0, o0.t12HB, o0.t12l),
  new q0(16, 0, o0.t13HB, o0.t13l),
  new q0(0, 0, null, o0.t16_5l),
  /* Apparently not used */
  new q0(16, 0, o0.t15HB, o0.t15l),
  new q0(1, 1, o0.t16HB, o0.t16l),
  new q0(2, 3, o0.t16HB, o0.t16l),
  new q0(3, 7, o0.t16HB, o0.t16l),
  new q0(4, 15, o0.t16HB, o0.t16l),
  new q0(6, 63, o0.t16HB, o0.t16l),
  new q0(8, 255, o0.t16HB, o0.t16l),
  new q0(10, 1023, o0.t16HB, o0.t16l),
  new q0(13, 8191, o0.t16HB, o0.t16l),
  new q0(4, 15, o0.t24HB, o0.t24l),
  new q0(5, 31, o0.t24HB, o0.t24l),
  new q0(6, 63, o0.t24HB, o0.t24l),
  new q0(7, 127, o0.t24HB, o0.t24l),
  new q0(8, 255, o0.t24HB, o0.t24l),
  new q0(9, 511, o0.t24HB, o0.t24l),
  new q0(11, 2047, o0.t24HB, o0.t24l),
  new q0(13, 8191, o0.t24HB, o0.t24l),
  new q0(0, 0, o0.t32HB, o0.t32l),
  new q0(0, 0, o0.t33HB, o0.t33l)
];
o0.largetbl = [
  65540,
  327685,
  458759,
  589832,
  655369,
  655370,
  720906,
  720907,
  786443,
  786444,
  786444,
  851980,
  851980,
  851980,
  917517,
  655370,
  262149,
  393222,
  524295,
  589832,
  655369,
  720906,
  720906,
  720907,
  786443,
  786443,
  786444,
  851980,
  917516,
  851980,
  917516,
  655370,
  458759,
  524295,
  589832,
  655369,
  720905,
  720906,
  786442,
  786443,
  851979,
  786443,
  851979,
  851980,
  851980,
  917516,
  917517,
  720905,
  589832,
  589832,
  655369,
  720905,
  720906,
  786442,
  786442,
  786443,
  851979,
  851979,
  917515,
  917516,
  917516,
  983052,
  983052,
  786441,
  655369,
  655369,
  720905,
  720906,
  786442,
  786442,
  851978,
  851979,
  851979,
  917515,
  917516,
  917516,
  983052,
  983052,
  983053,
  720905,
  655370,
  655369,
  720906,
  720906,
  786442,
  851978,
  851979,
  917515,
  851979,
  917515,
  917516,
  983052,
  983052,
  983052,
  1048588,
  786441,
  720906,
  720906,
  720906,
  786442,
  851978,
  851979,
  851979,
  851979,
  917515,
  917516,
  917516,
  917516,
  983052,
  983052,
  1048589,
  786441,
  720907,
  720906,
  786442,
  786442,
  851979,
  851979,
  851979,
  917515,
  917516,
  983052,
  983052,
  983052,
  983052,
  1114125,
  1114125,
  786442,
  720907,
  786443,
  786443,
  851979,
  851979,
  851979,
  917515,
  917515,
  983051,
  983052,
  983052,
  983052,
  1048588,
  1048589,
  1048589,
  786442,
  786443,
  786443,
  786443,
  851979,
  851979,
  917515,
  917515,
  983052,
  983052,
  983052,
  983052,
  1048588,
  983053,
  1048589,
  983053,
  851978,
  786444,
  851979,
  786443,
  851979,
  917515,
  917516,
  917516,
  917516,
  983052,
  1048588,
  1048588,
  1048589,
  1114125,
  1114125,
  1048589,
  786442,
  851980,
  851980,
  851979,
  851979,
  917515,
  917516,
  983052,
  1048588,
  1048588,
  1048588,
  1048588,
  1048589,
  1048589,
  983053,
  1048589,
  851978,
  851980,
  917516,
  917516,
  917516,
  917516,
  983052,
  983052,
  983052,
  983052,
  1114124,
  1048589,
  1048589,
  1048589,
  1048589,
  1179661,
  851978,
  983052,
  917516,
  917516,
  917516,
  983052,
  983052,
  1048588,
  1048588,
  1048589,
  1179661,
  1114125,
  1114125,
  1114125,
  1245197,
  1114125,
  851978,
  917517,
  983052,
  851980,
  917516,
  1048588,
  1048588,
  983052,
  1048589,
  1048589,
  1114125,
  1179661,
  1114125,
  1245197,
  1114125,
  1048589,
  851978,
  655369,
  655369,
  655369,
  720905,
  720905,
  786441,
  786441,
  786441,
  851977,
  851977,
  851977,
  851978,
  851978,
  851978,
  851978,
  655366
];
o0.table23 = [
  65538,
  262147,
  458759,
  262148,
  327684,
  458759,
  393222,
  458759,
  524296
];
o0.table56 = [
  65539,
  262148,
  458758,
  524296,
  262148,
  327684,
  524294,
  589831,
  458757,
  524294,
  589831,
  655368,
  524295,
  524295,
  589832,
  655369
];
o0.bitrate_table = [
  [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, -1],
  /* MPEG 2 */
  [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, -1],
  /* MPEG 1 */
  [0, 8, 16, 24, 32, 40, 48, 56, 64, -1, -1, -1, -1, -1, -1, -1]
  /* MPEG 2.5 */
];
o0.samplerate_table = [
  [22050, 24e3, 16e3, -1],
  [44100, 48e3, 32e3, -1],
  [11025, 12e3, 8e3, -1]
];
o0.scfsi_band = [0, 6, 11, 16, 21];
var He = o0, Me, ra;
function Va() {
  if (ra)
    return Me;
  ra = 1;
  var w = Ia, Z = Q0, X = Z.VbrMode, z = Z.Float, u0 = Z.Util, W = Z.new_float, Q = Z.new_int, D = Z.assert, g = t1(), f0 = Ha, A = ne;
  m.Q_MAX = 256 + 1, m.Q_MAX2 = 116, m.LARGE_BITS = 1e5, m.IXMAX_VAL = 8206;
  function m() {
    var O = Ve(), s0 = null, K = null, t0 = null;
    this.setModules = function(S, L, V) {
      s0 = S, K = L, t0 = V;
    };
    function U(S) {
      return D(0 <= S + m.Q_MAX2 && S < m.Q_MAX), p[S + m.Q_MAX2];
    }
    this.IPOW20 = function(S) {
      return D(0 <= S && S < m.Q_MAX), H[S];
    };
    var R = 2220446049250313e-31, o = m.IXMAX_VAL, u = o + 2, d = m.Q_MAX, e = m.Q_MAX2;
    m.LARGE_BITS;
    var l = 100;
    this.nr_of_sfb_block = [
      [[6, 5, 5, 5], [9, 9, 9, 9], [6, 9, 9, 9]],
      [[6, 5, 7, 3], [9, 9, 12, 6], [6, 9, 12, 6]],
      [[11, 10, 0, 0], [18, 18, 0, 0], [15, 18, 0, 0]],
      [[7, 7, 7, 0], [12, 12, 12, 0], [6, 15, 12, 0]],
      [[6, 6, 6, 3], [12, 9, 9, 6], [6, 12, 9, 6]],
      [[8, 8, 5, 0], [15, 12, 9, 0], [6, 18, 9, 0]]
    ];
    var M = [
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      1,
      1,
      1,
      1,
      2,
      2,
      3,
      3,
      3,
      2,
      0
    ];
    this.pretab = M, this.sfBandIndex = [
      // Table B.2.b: 22.05 kHz
      new w(
        [
          0,
          6,
          12,
          18,
          24,
          30,
          36,
          44,
          54,
          66,
          80,
          96,
          116,
          140,
          168,
          200,
          238,
          284,
          336,
          396,
          464,
          522,
          576
        ],
        [0, 4, 8, 12, 18, 24, 32, 42, 56, 74, 100, 132, 174, 192],
        [0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0]
        //  sfb12 pseudo sub bands
      ),
      /* Table B.2.c: 24 kHz */
      /* docs: 332. mpg123(broken): 330 */
      new w(
        [
          0,
          6,
          12,
          18,
          24,
          30,
          36,
          44,
          54,
          66,
          80,
          96,
          114,
          136,
          162,
          194,
          232,
          278,
          332,
          394,
          464,
          540,
          576
        ],
        [0, 4, 8, 12, 18, 26, 36, 48, 62, 80, 104, 136, 180, 192],
        [0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0]
        /*  sfb12 pseudo sub bands */
      ),
      /* Table B.2.a: 16 kHz */
      new w(
        [
          0,
          6,
          12,
          18,
          24,
          30,
          36,
          44,
          54,
          66,
          80,
          96,
          116,
          140,
          168,
          200,
          238,
          284,
          336,
          396,
          464,
          522,
          576
        ],
        [0, 4, 8, 12, 18, 26, 36, 48, 62, 80, 104, 134, 174, 192],
        [0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0]
        /*  sfb12 pseudo sub bands */
      ),
      /* Table B.8.b: 44.1 kHz */
      new w(
        [
          0,
          4,
          8,
          12,
          16,
          20,
          24,
          30,
          36,
          44,
          52,
          62,
          74,
          90,
          110,
          134,
          162,
          196,
          238,
          288,
          342,
          418,
          576
        ],
        [0, 4, 8, 12, 16, 22, 30, 40, 52, 66, 84, 106, 136, 192],
        [0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0]
        /*  sfb12 pseudo sub bands */
      ),
      /* Table B.8.c: 48 kHz */
      new w(
        [
          0,
          4,
          8,
          12,
          16,
          20,
          24,
          30,
          36,
          42,
          50,
          60,
          72,
          88,
          106,
          128,
          156,
          190,
          230,
          276,
          330,
          384,
          576
        ],
        [0, 4, 8, 12, 16, 22, 28, 38, 50, 64, 80, 100, 126, 192],
        [0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0]
        /*  sfb12 pseudo sub bands */
      ),
      /* Table B.8.a: 32 kHz */
      new w(
        [
          0,
          4,
          8,
          12,
          16,
          20,
          24,
          30,
          36,
          44,
          54,
          66,
          82,
          102,
          126,
          156,
          194,
          240,
          296,
          364,
          448,
          550,
          576
        ],
        [0, 4, 8, 12, 16, 22, 30, 42, 58, 78, 104, 138, 180, 192],
        [0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0]
        /*  sfb12 pseudo sub bands */
      ),
      /* MPEG-2.5 11.025 kHz */
      new w(
        [
          0,
          6,
          12,
          18,
          24,
          30,
          36,
          44,
          54,
          66,
          80,
          96,
          116,
          140,
          168,
          200,
          238,
          284,
          336,
          396,
          464,
          522,
          576
        ],
        [
          0 / 3,
          12 / 3,
          24 / 3,
          36 / 3,
          54 / 3,
          78 / 3,
          108 / 3,
          144 / 3,
          186 / 3,
          240 / 3,
          312 / 3,
          402 / 3,
          522 / 3,
          576 / 3
        ],
        [0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0]
        /*  sfb12 pseudo sub bands */
      ),
      /* MPEG-2.5 12 kHz */
      new w(
        [
          0,
          6,
          12,
          18,
          24,
          30,
          36,
          44,
          54,
          66,
          80,
          96,
          116,
          140,
          168,
          200,
          238,
          284,
          336,
          396,
          464,
          522,
          576
        ],
        [
          0 / 3,
          12 / 3,
          24 / 3,
          36 / 3,
          54 / 3,
          78 / 3,
          108 / 3,
          144 / 3,
          186 / 3,
          240 / 3,
          312 / 3,
          402 / 3,
          522 / 3,
          576 / 3
        ],
        [0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0]
        /*  sfb12 pseudo sub bands */
      ),
      /* MPEG-2.5 8 kHz */
      new w(
        [
          0,
          12,
          24,
          36,
          48,
          60,
          72,
          88,
          108,
          132,
          160,
          192,
          232,
          280,
          336,
          400,
          476,
          566,
          568,
          570,
          572,
          574,
          576
        ],
        [
          0 / 3,
          24 / 3,
          48 / 3,
          72 / 3,
          108 / 3,
          156 / 3,
          216 / 3,
          288 / 3,
          372 / 3,
          480 / 3,
          486 / 3,
          492 / 3,
          498 / 3,
          576 / 3
        ],
        [0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0]
        /*  sfb12 pseudo sub bands */
      )
    ];
    var p = W(d + e + 1), H = W(d), B = W(u), I = W(u);
    this.adj43 = I;
    function v0(S, L) {
      var V = t0.ATHformula(L, S);
      return V -= l, V = Math.pow(10, V / 10 + S.ATHlower), V;
    }
    function b(S) {
      for (var L = S.internal_flags.ATH.l, V = S.internal_flags.ATH.psfb21, N = S.internal_flags.ATH.s, P = S.internal_flags.ATH.psfb12, E = S.internal_flags, i = S.out_samplerate, s = 0; s < g.SBMAX_l; s++) {
        var r = E.scalefac_band.l[s], n = E.scalefac_band.l[s + 1];
        L[s] = z.MAX_VALUE;
        for (var f = r; f < n; f++) {
          var Y = f * i / 1152, J = v0(S, Y);
          L[s] = Math.min(L[s], J);
        }
      }
      for (var s = 0; s < g.PSFB21; s++) {
        var r = E.scalefac_band.psfb21[s], n = E.scalefac_band.psfb21[s + 1];
        V[s] = z.MAX_VALUE;
        for (var f = r; f < n; f++) {
          var Y = f * i / 1152, J = v0(S, Y);
          V[s] = Math.min(V[s], J);
        }
      }
      for (var s = 0; s < g.SBMAX_s; s++) {
        var r = E.scalefac_band.s[s], n = E.scalefac_band.s[s + 1];
        N[s] = z.MAX_VALUE;
        for (var f = r; f < n; f++) {
          var Y = f * i / 384, J = v0(S, Y);
          N[s] = Math.min(N[s], J);
        }
        N[s] *= E.scalefac_band.s[s + 1] - E.scalefac_band.s[s];
      }
      for (var s = 0; s < g.PSFB12; s++) {
        var r = E.scalefac_band.psfb12[s], n = E.scalefac_band.psfb12[s + 1];
        P[s] = z.MAX_VALUE;
        for (var f = r; f < n; f++) {
          var Y = f * i / 384, J = v0(S, Y);
          P[s] = Math.min(P[s], J);
        }
        P[s] *= E.scalefac_band.s[13] - E.scalefac_band.s[12];
      }
      if (S.noATH) {
        for (var s = 0; s < g.SBMAX_l; s++)
          L[s] = 1e-20;
        for (var s = 0; s < g.PSFB21; s++)
          V[s] = 1e-20;
        for (var s = 0; s < g.SBMAX_s; s++)
          N[s] = 1e-20;
        for (var s = 0; s < g.PSFB12; s++)
          P[s] = 1e-20;
      }
      E.ATH.floor = 10 * Math.log10(v0(S, -1));
    }
    this.iteration_init = function(S) {
      var L = S.internal_flags, V = L.l3_side, N;
      if (L.iteration_init_init == 0) {
        for (L.iteration_init_init = 1, V.main_data_begin = 0, b(S), B[0] = 0, N = 1; N < u; N++)
          B[N] = Math.pow(N, 4 / 3);
        for (N = 0; N < u - 1; N++)
          I[N] = N + 1 - Math.pow(
            0.5 * (B[N] + B[N + 1]),
            0.75
          );
        for (I[N] = 0.5, N = 0; N < d; N++)
          H[N] = Math.pow(2, (N - 210) * -0.1875);
        for (N = 0; N <= d + e; N++)
          p[N] = Math.pow(2, (N - 210 - e) * 0.25);
        s0.huffman_init(L);
        {
          var P, E, i, s;
          for (N = S.exp_nspsytune >> 2 & 63, N >= 32 && (N -= 64), P = Math.pow(10, N / 4 / 10), N = S.exp_nspsytune >> 8 & 63, N >= 32 && (N -= 64), E = Math.pow(10, N / 4 / 10), N = S.exp_nspsytune >> 14 & 63, N >= 32 && (N -= 64), i = Math.pow(10, N / 4 / 10), N = S.exp_nspsytune >> 20 & 63, N >= 32 && (N -= 64), s = i * Math.pow(10, N / 4 / 10), N = 0; N < g.SBMAX_l; N++) {
            var r;
            N <= 6 ? r = P : N <= 13 ? r = E : N <= 20 ? r = i : r = s, L.nsPsy.longfact[N] = r;
          }
          for (N = 0; N < g.SBMAX_s; N++) {
            var r;
            N <= 5 ? r = P : N <= 10 ? r = E : N <= 11 ? r = i : r = s, L.nsPsy.shortfact[N] = r;
          }
        }
      }
    }, this.on_pe = function(S, L, V, N, P, E) {
      var i = S.internal_flags, s = 0, r, n = Q(2), f, Y = new f0(s), J = K.ResvMaxBits(S, N, Y, E);
      s = Y.bits;
      var T = s + J;
      for (T > A.MAX_BITS_PER_GRANULE && (T = A.MAX_BITS_PER_GRANULE), r = 0, f = 0; f < i.channels_out; ++f)
        V[f] = Math.min(
          A.MAX_BITS_PER_CHANNEL,
          s / i.channels_out
        ), n[f] = 0 | V[f] * L[P][f] / 700 - V[f], n[f] > N * 3 / 4 && (n[f] = N * 3 / 4), n[f] < 0 && (n[f] = 0), n[f] + V[f] > A.MAX_BITS_PER_CHANNEL && (n[f] = Math.max(
          0,
          A.MAX_BITS_PER_CHANNEL - V[f]
        )), r += n[f];
      if (r > J)
        for (f = 0; f < i.channels_out; ++f)
          n[f] = J * n[f] / r;
      for (f = 0; f < i.channels_out; ++f)
        V[f] += n[f], J -= n[f];
      for (r = 0, f = 0; f < i.channels_out; ++f)
        r += V[f];
      if (r > A.MAX_BITS_PER_GRANULE) {
        var q = 0;
        for (f = 0; f < i.channels_out; ++f)
          V[f] *= A.MAX_BITS_PER_GRANULE, V[f] /= r, q += V[f];
      }
      return T;
    }, this.reduce_side = function(S, L, V, N) {
      D(S[0] + S[1] <= A.MAX_BITS_PER_GRANULE);
      var P = 0.33 * (0.5 - L) / 0.5;
      P < 0 && (P = 0), P > 0.5 && (P = 0.5);
      var E = 0 | P * 0.5 * (S[0] + S[1]);
      E > A.MAX_BITS_PER_CHANNEL - S[0] && (E = A.MAX_BITS_PER_CHANNEL - S[0]), E < 0 && (E = 0), S[1] >= 125 && (S[1] - E > 125 ? (S[0] < V && (S[0] += E), S[1] -= E) : (S[0] += S[1] - 125, S[1] = 125)), E = S[0] + S[1], E > N && (S[0] = N * S[0] / E, S[1] = N * S[1] / E), D(S[0] <= A.MAX_BITS_PER_CHANNEL), D(S[1] <= A.MAX_BITS_PER_CHANNEL), D(S[0] + S[1] <= A.MAX_BITS_PER_GRANULE);
    }, this.athAdjust = function(S, L, V) {
      var N = 90.30873362, P = 94.82444863, E = u0.FAST_LOG10_X(L, 10), i = S * S, s = 0;
      return E -= V, i > 1e-20 && (s = 1 + u0.FAST_LOG10_X(i, 10 / N)), s < 0 && (s = 0), E *= s, E += V + N - P, Math.pow(10, 0.1 * E);
    }, this.calc_xmin = function(S, L, V, N) {
      var P = 0, E = S.internal_flags, i, s = 0, r = 0, n = E.ATH, f = V.xr, Y = S.VBR == X.vbr_mtrh ? 1 : 0, J = E.masking_lower;
      for ((S.VBR == X.vbr_mtrh || S.VBR == X.vbr_mt) && (J = 1), i = 0; i < V.psy_lmax; i++) {
        var T, q, i0, h0, d0, M0;
        S.VBR == X.vbr_rh || S.VBR == X.vbr_mtrh ? q = athAdjust(n.adjust, n.l[i], n.floor) : q = n.adjust * n.l[i], d0 = V.width[i], i0 = q / d0, h0 = R, M0 = d0 >> 1, T = 0;
        do {
          var R0, A0;
          R0 = f[s] * f[s], T += R0, h0 += R0 < i0 ? R0 : i0, s++, A0 = f[s] * f[s], T += A0, h0 += A0 < i0 ? A0 : i0, s++;
        } while (--M0 > 0);
        if (T > q && r++, i == g.SBPSY_l) {
          var w0 = q * E.nsPsy.longfact[i];
          h0 < w0 && (h0 = w0);
        }
        if (Y != 0 && (q = h0), !S.ATHonly) {
          var $0 = L.en.l[i];
          if ($0 > 0) {
            var w0;
            w0 = T * L.thm.l[i] * J / $0, Y != 0 && (w0 *= E.nsPsy.longfact[i]), q < w0 && (q = w0);
          }
        }
        Y != 0 ? N[P++] = q : N[P++] = q * E.nsPsy.longfact[i];
      }
      var f1 = 575;
      if (V.block_type != g.SHORT_TYPE)
        for (var t = 576; t-- != 0 && O.EQ(f[t], 0); )
          f1 = t;
      V.max_nonzero_coeff = f1;
      for (var _ = V.sfb_smin; i < V.psymax; _++, i += 3) {
        var d0, S0, E0;
        for (S.VBR == X.vbr_rh || S.VBR == X.vbr_mtrh ? E0 = athAdjust(n.adjust, n.s[_], n.floor) : E0 = n.adjust * n.s[_], d0 = V.width[i], S0 = 0; S0 < 3; S0++) {
          var T = 0, q, i0, h0, M0 = d0 >> 1;
          i0 = E0 / d0, h0 = R;
          do {
            var R0, A0;
            R0 = f[s] * f[s], T += R0, h0 += R0 < i0 ? R0 : i0, s++, A0 = f[s] * f[s], T += A0, h0 += A0 < i0 ? A0 : i0, s++;
          } while (--M0 > 0);
          if (T > E0 && r++, _ == g.SBPSY_s) {
            var w0 = E0 * E.nsPsy.shortfact[_];
            h0 < w0 && (h0 = w0);
          }
          if (Y != 0 ? q = h0 : q = E0, !S.ATHonly && !S.ATHshort) {
            var $0 = L.en.s[_][S0];
            if ($0 > 0) {
              var w0;
              w0 = T * L.thm.s[_][S0] * J / $0, Y != 0 && (w0 *= E.nsPsy.shortfact[_]), q < w0 && (q = w0);
            }
          }
          Y != 0 ? N[P++] = q : N[P++] = q * E.nsPsy.shortfact[_];
        }
        S.useTemporal && (N[P - 3] > N[P - 3 + 1] && (N[P - 3 + 1] += (N[P - 3] - N[P - 3 + 1]) * E.decay), N[P - 3 + 1] > N[P - 3 + 2] && (N[P - 3 + 2] += (N[P - 3 + 1] - N[P - 3 + 2]) * E.decay));
      }
      return r;
    };
    function a(S) {
      this.s = S;
    }
    this.calc_noise_core = function(S, L, V, N) {
      var P = 0, E = L.s, i = S.l3_enc;
      if (E > S.count1)
        for (; V-- != 0; ) {
          var s;
          s = S.xr[E], E++, P += s * s, s = S.xr[E], E++, P += s * s;
        }
      else if (E > S.big_values) {
        var r = W(2);
        for (r[0] = 0, r[1] = N; V-- != 0; ) {
          var s;
          s = Math.abs(S.xr[E]) - r[i[E]], E++, P += s * s, s = Math.abs(S.xr[E]) - r[i[E]], E++, P += s * s;
        }
      } else
        for (; V-- != 0; ) {
          var s;
          s = Math.abs(S.xr[E]) - B[i[E]] * N, E++, P += s * s, s = Math.abs(S.xr[E]) - B[i[E]] * N, E++, P += s * s;
        }
      return L.s = E, P;
    }, this.calc_noise = function(S, L, V, N, P) {
      var E = 0, i = 0, s, r, n = 0, f = 0, Y = 0, J = -20, T = 0, q = S.scalefac, i0 = 0;
      for (N.over_SSD = 0, s = 0; s < S.psymax; s++) {
        var h0 = S.global_gain - (q[i0++] + (S.preflag != 0 ? M[s] : 0) << S.scalefac_scale + 1) - S.subblock_gain[S.window[s]] * 8, d0 = 0;
        if (P != null && P.step[s] == h0)
          d0 = P.noise[s], T += S.width[s], V[E++] = d0 / L[i++], d0 = P.noise_log[s];
        else {
          var M0 = U(h0);
          if (r = S.width[s] >> 1, T + S.width[s] > S.max_nonzero_coeff) {
            var R0;
            R0 = S.max_nonzero_coeff - T + 1, R0 > 0 ? r = R0 >> 1 : r = 0;
          }
          var A0 = new a(T);
          d0 = this.calc_noise_core(S, A0, r, M0), T = A0.s, P != null && (P.step[s] = h0, P.noise[s] = d0), d0 = V[E++] = d0 / L[i++], d0 = u0.FAST_LOG10(Math.max(d0, 1e-20)), P != null && (P.noise_log[s] = d0);
        }
        if (P != null && (P.global_gain = S.global_gain), Y += d0, d0 > 0) {
          var w0;
          w0 = Math.max(0 | d0 * 10 + 0.5, 1), N.over_SSD += w0 * w0, n++, f += d0;
        }
        J = Math.max(J, d0);
      }
      return N.over_count = n, N.tot_noise = Y, N.over_noise = f, N.max_noise = J, n;
    }, this.set_pinfo = function(S, L, V, N, P) {
      var E = S.internal_flags, i, s, r, n, f, Y = L.scalefac_scale == 0 ? 0.5 : 1, J = L.scalefac, T = W(L3Side.SFBMAX), q = W(L3Side.SFBMAX), i0 = new CalcNoiseResult();
      calc_xmin(S, V, L, T), calc_noise(L, T, q, i0, null);
      var h0 = 0;
      for (s = L.sfb_lmax, L.block_type != g.SHORT_TYPE && L.mixed_block_flag == 0 && (s = 22), i = 0; i < s; i++) {
        var d0 = E.scalefac_band.l[i], M0 = E.scalefac_band.l[i + 1], R0 = M0 - d0;
        for (n = 0; h0 < M0; h0++)
          n += L.xr[h0] * L.xr[h0];
        n /= R0, f = 1e15, E.pinfo.en[N][P][i] = f * n, E.pinfo.xfsf[N][P][i] = f * T[i] * q[i] / R0, V.en.l[i] > 0 && !S.ATHonly ? n = n / V.en.l[i] : n = 0, E.pinfo.thr[N][P][i] = f * Math.max(n * V.thm.l[i], E.ATH.l[i]), E.pinfo.LAMEsfb[N][P][i] = 0, L.preflag != 0 && i >= 11 && (E.pinfo.LAMEsfb[N][P][i] = -Y * M[i]), i < g.SBPSY_l && (D(J[i] >= 0), E.pinfo.LAMEsfb[N][P][i] -= Y * J[i]);
      }
      if (L.block_type == g.SHORT_TYPE)
        for (s = i, i = L.sfb_smin; i < g.SBMAX_s; i++)
          for (var d0 = E.scalefac_band.s[i], M0 = E.scalefac_band.s[i + 1], R0 = M0 - d0, A0 = 0; A0 < 3; A0++) {
            for (n = 0, r = d0; r < M0; r++)
              n += L.xr[h0] * L.xr[h0], h0++;
            n = Math.max(n / R0, 1e-20), f = 1e15, E.pinfo.en_s[N][P][3 * i + A0] = f * n, E.pinfo.xfsf_s[N][P][3 * i + A0] = f * T[s] * q[s] / R0, V.en.s[i][A0] > 0 ? n = n / V.en.s[i][A0] : n = 0, (S.ATHonly || S.ATHshort) && (n = 0), E.pinfo.thr_s[N][P][3 * i + A0] = f * Math.max(
              n * V.thm.s[i][A0],
              E.ATH.s[i]
            ), E.pinfo.LAMEsfb_s[N][P][3 * i + A0] = -2 * L.subblock_gain[A0], i < g.SBPSY_s && (E.pinfo.LAMEsfb_s[N][P][3 * i + A0] -= Y * J[s]), s++;
          }
      E.pinfo.LAMEqss[N][P] = L.global_gain, E.pinfo.LAMEmainbits[N][P] = L.part2_3_length + L.part2_length, E.pinfo.LAMEsfbits[N][P] = L.part2_length, E.pinfo.over[N][P] = i0.over_count, E.pinfo.max_noise[N][P] = i0.max_noise * 10, E.pinfo.over_noise[N][P] = i0.over_noise * 10, E.pinfo.tot_noise[N][P] = i0.tot_noise * 10, E.pinfo.over_SSD[N][P] = i0.over_SSD;
    };
  }
  return Me = m, Me;
}
var Ee, ta;
function Oa() {
  if (ta)
    return Ee;
  ta = 1;
  var w = Q0, Z = w.System, X = w.Arrays, z = w.new_int, u0 = w.assert, W = t1(), Q = He, D = Le, g = Va();
  function f0() {
    var A = null;
    this.qupvt = null, this.setModules = function(E) {
      this.qupvt = E, A = E;
    };
    function m(E) {
      this.bits = 0 | E;
    }
    var O = [
      [0, 0],
      /* 0 bands */
      [0, 0],
      /* 1 bands */
      [0, 0],
      /* 2 bands */
      [0, 0],
      /* 3 bands */
      [0, 0],
      /* 4 bands */
      [0, 1],
      /* 5 bands */
      [1, 1],
      /* 6 bands */
      [1, 1],
      /* 7 bands */
      [1, 2],
      /* 8 bands */
      [2, 2],
      /* 9 bands */
      [2, 3],
      /* 10 bands */
      [2, 3],
      /* 11 bands */
      [3, 4],
      /* 12 bands */
      [3, 4],
      /* 13 bands */
      [3, 4],
      /* 14 bands */
      [4, 5],
      /* 15 bands */
      [4, 5],
      /* 16 bands */
      [4, 6],
      /* 17 bands */
      [5, 6],
      /* 18 bands */
      [5, 6],
      /* 19 bands */
      [5, 7],
      /* 20 bands */
      [6, 7],
      /* 21 bands */
      [6, 7]
      /* 22 bands */
    ];
    function s0(E, i, s, r, n, f) {
      var Y = 0.5946 / i;
      for (E = E >> 1; E-- != 0; )
        n[f++] = Y > s[r++] ? 0 : 1, n[f++] = Y > s[r++] ? 0 : 1;
    }
    function K(E, i, s, r, n, f) {
      E = E >> 1;
      var Y = E % 2;
      for (E = E >> 1; E-- != 0; ) {
        var J, T, q, i0, h0, d0, M0, R0;
        J = s[r++] * i, T = s[r++] * i, h0 = 0 | J, q = s[r++] * i, d0 = 0 | T, i0 = s[r++] * i, M0 = 0 | q, J += A.adj43[h0], R0 = 0 | i0, T += A.adj43[d0], n[f++] = 0 | J, q += A.adj43[M0], n[f++] = 0 | T, i0 += A.adj43[R0], n[f++] = 0 | q, n[f++] = 0 | i0;
      }
      if (Y != 0) {
        var J, T, h0, d0;
        J = s[r++] * i, T = s[r++] * i, h0 = 0 | J, d0 = 0 | T, J += A.adj43[h0], T += A.adj43[d0], n[f++] = 0 | J, n[f++] = 0 | T;
      }
    }
    function t0(E, i, s, r, n) {
      var f, Y, J = 0, T, q = 0, i0 = 0, h0 = 0, d0 = i, M0 = 0, R0 = d0, A0 = 0, w0 = E, $0 = 0;
      for (T = n != null && r.global_gain == n.global_gain, r.block_type == W.SHORT_TYPE ? Y = 38 : Y = 21, f = 0; f <= Y; f++) {
        var f1 = -1;
        if ((T || r.block_type == W.NORM_TYPE) && (f1 = r.global_gain - (r.scalefac[f] + (r.preflag != 0 ? A.pretab[f] : 0) << r.scalefac_scale + 1) - r.subblock_gain[r.window[f]] * 8), u0(r.width[f] >= 0), T && n.step[f] == f1)
          q != 0 && (K(
            q,
            s,
            w0,
            $0,
            R0,
            A0
          ), q = 0), i0 != 0 && (s0(
            i0,
            s,
            w0,
            $0,
            R0,
            A0
          ), i0 = 0);
        else {
          var t = r.width[f];
          if (J + r.width[f] > r.max_nonzero_coeff) {
            var _;
            _ = r.max_nonzero_coeff - J + 1, X.fill(i, r.max_nonzero_coeff, 576, 0), t = _, t < 0 && (t = 0), f = Y + 1;
          }
          if (q == 0 && i0 == 0 && (R0 = d0, A0 = M0, w0 = E, $0 = h0), n != null && n.sfb_count1 > 0 && f >= n.sfb_count1 && n.step[f] > 0 && f1 >= n.step[f] ? (q != 0 && (K(
            q,
            s,
            w0,
            $0,
            R0,
            A0
          ), q = 0, R0 = d0, A0 = M0, w0 = E, $0 = h0), i0 += t) : (i0 != 0 && (s0(
            i0,
            s,
            w0,
            $0,
            R0,
            A0
          ), i0 = 0, R0 = d0, A0 = M0, w0 = E, $0 = h0), q += t), t <= 0) {
            i0 != 0 && (s0(
              i0,
              s,
              w0,
              $0,
              R0,
              A0
            ), i0 = 0), q != 0 && (K(
              q,
              s,
              w0,
              $0,
              R0,
              A0
            ), q = 0);
            break;
          }
        }
        f <= Y && (M0 += r.width[f], h0 += r.width[f], J += r.width[f]);
      }
      q != 0 && (K(
        q,
        s,
        w0,
        $0,
        R0,
        A0
      ), q = 0), i0 != 0 && (s0(
        i0,
        s,
        w0,
        $0,
        R0,
        A0
      ), i0 = 0);
    }
    function U(E, i, s) {
      var r = 0, n = 0;
      do {
        var f = E[i++], Y = E[i++];
        r < f && (r = f), n < Y && (n = Y);
      } while (i < s);
      return r < n && (r = n), r;
    }
    function R(E, i, s, r, n, f) {
      var Y = Q.ht[r].xlen * 65536 + Q.ht[n].xlen, J = 0, T;
      do {
        var q = E[i++], i0 = E[i++];
        q != 0 && (q > 14 && (q = 15, J += Y), q *= 16), i0 != 0 && (i0 > 14 && (i0 = 15, J += Y), q += i0), J += Q.largetbl[q];
      } while (i < s);
      return T = J & 65535, J >>= 16, J > T && (J = T, r = n), f.bits += J, r;
    }
    function o(E, i, s, r) {
      var n = 0, f = Q.ht[1].hlen;
      do {
        var Y = E[i + 0] * 2 + E[i + 1];
        i += 2, n += f[Y];
      } while (i < s);
      return r.bits += n, 1;
    }
    function u(E, i, s, r, n) {
      var f = 0, Y, J = Q.ht[r].xlen, T;
      r == 2 ? T = Q.table23 : T = Q.table56;
      do {
        var q = E[i + 0] * J + E[i + 1];
        i += 2, f += T[q];
      } while (i < s);
      return Y = f & 65535, f >>= 16, f > Y && (f = Y, r++), n.bits += f, r;
    }
    function d(E, i, s, r, n) {
      var f = 0, Y = 0, J = 0, T = Q.ht[r].xlen, q = Q.ht[r].hlen, i0 = Q.ht[r + 1].hlen, h0 = Q.ht[r + 2].hlen;
      do {
        var d0 = E[i + 0] * T + E[i + 1];
        i += 2, f += q[d0], Y += i0[d0], J += h0[d0];
      } while (i < s);
      var M0 = r;
      return f > Y && (f = Y, M0++), f > J && (f = J, M0 = r + 2), n.bits += f, M0;
    }
    var e = [
      1,
      2,
      5,
      7,
      7,
      10,
      10,
      13,
      13,
      13,
      13,
      13,
      13,
      13,
      13
    ];
    function l(E, i, s, r) {
      var n = U(E, i, s);
      switch (n) {
        case 0:
          return n;
        case 1:
          return o(E, i, s, r);
        case 2:
        case 3:
          return u(
            E,
            i,
            s,
            e[n - 1],
            r
          );
        case 4:
        case 5:
        case 6:
        case 7:
        case 8:
        case 9:
        case 10:
        case 11:
        case 12:
        case 13:
        case 14:
        case 15:
          return d(
            E,
            i,
            s,
            e[n - 1],
            r
          );
        default:
          if (n > g.IXMAX_VAL)
            return r.bits = g.LARGE_BITS, -1;
          n -= 15;
          var f;
          for (f = 24; f < 32 && !(Q.ht[f].linmax >= n); f++)
            ;
          var Y;
          for (Y = f - 8; Y < 24 && !(Q.ht[Y].linmax >= n); Y++)
            ;
          return R(E, i, s, Y, f, r);
      }
    }
    this.noquant_count_bits = function(E, i, s) {
      var r = i.l3_enc, n = Math.min(576, i.max_nonzero_coeff + 2 >> 1 << 1);
      for (s != null && (s.sfb_count1 = 0); n > 1 && !(r[n - 1] | r[n - 2]); n -= 2)
        ;
      i.count1 = n;
      for (var f = 0, Y = 0; n > 3; n -= 4) {
        var J;
        if (((r[n - 1] | r[n - 2] | r[n - 3] | r[n - 4]) & 2147483647) > 1)
          break;
        J = ((r[n - 4] * 2 + r[n - 3]) * 2 + r[n - 2]) * 2 + r[n - 1], f += Q.t32l[J], Y += Q.t33l[J];
      }
      var T = f;
      if (i.count1table_select = 0, f > Y && (T = Y, i.count1table_select = 1), i.count1bits = T, i.big_values = n, n == 0)
        return T;
      if (i.block_type == W.SHORT_TYPE)
        f = 3 * E.scalefac_band.s[3], f > i.big_values && (f = i.big_values), Y = i.big_values;
      else if (i.block_type == W.NORM_TYPE) {
        if (f = i.region0_count = E.bv_scf[n - 2], Y = i.region1_count = E.bv_scf[n - 1], u0(f + Y + 2 < W.SBPSY_l), Y = E.scalefac_band.l[f + Y + 2], f = E.scalefac_band.l[f + 1], Y < n) {
          var q = new m(T);
          i.table_select[2] = l(r, Y, n, q), T = q.bits;
        }
      } else
        i.region0_count = 7, i.region1_count = W.SBMAX_l - 1 - 7 - 1, f = E.scalefac_band.l[7 + 1], Y = n, f > Y && (f = Y);
      if (f = Math.min(f, n), Y = Math.min(Y, n), 0 < f) {
        var q = new m(T);
        i.table_select[0] = l(r, 0, f, q), T = q.bits;
      }
      if (f < Y) {
        var q = new m(T);
        i.table_select[1] = l(r, f, Y, q), T = q.bits;
      }
      if (E.use_best_huffman == 2 && (i.part2_3_length = T, best_huffman_divide(E, i), T = i.part2_3_length), s != null && i.block_type == W.NORM_TYPE) {
        for (var i0 = 0; E.scalefac_band.l[i0] < i.big_values; )
          i0++;
        s.sfb_count1 = i0;
      }
      return T;
    }, this.count_bits = function(E, i, s, r) {
      var n = s.l3_enc, f = g.IXMAX_VAL / A.IPOW20(s.global_gain);
      if (s.xrpow_max > f)
        return g.LARGE_BITS;
      if (t0(i, n, A.IPOW20(s.global_gain), s, r), E.substep_shaping & 2)
        for (var Y = 0, J = s.global_gain + s.scalefac_scale, T = 0.634521682242439 / A.IPOW20(J), q = 0; q < s.sfbmax; q++) {
          var i0 = s.width[q];
          if (E.pseudohalf[q] == 0)
            Y += i0;
          else {
            var h0;
            for (h0 = Y, Y += i0; h0 < Y; ++h0)
              n[h0] = i[h0] >= T ? n[h0] : 0;
          }
        }
      return this.noquant_count_bits(E, s, r);
    };
    function M(E, i, s, r, n, f, Y) {
      for (var J = i.big_values, T = 0; T <= 7 + 15; T++)
        r[T] = g.LARGE_BITS;
      for (var T = 0; T < 16; T++) {
        var q = E.scalefac_band.l[T + 1];
        if (q >= J)
          break;
        var i0 = 0, h0 = new m(i0), d0 = l(s, 0, q, h0);
        i0 = h0.bits;
        for (var M0 = 0; M0 < 8; M0++) {
          var R0 = E.scalefac_band.l[T + M0 + 2];
          if (R0 >= J)
            break;
          var A0 = i0;
          h0 = new m(A0);
          var w0 = l(s, q, R0, h0);
          A0 = h0.bits, r[T + M0] > A0 && (r[T + M0] = A0, n[T + M0] = T, f[T + M0] = d0, Y[T + M0] = w0);
        }
      }
    }
    function p(E, i, s, r, n, f, Y, J) {
      for (var T = i.big_values, q = 2; q < W.SBMAX_l + 1; q++) {
        var i0 = E.scalefac_band.l[q];
        if (i0 >= T)
          break;
        var h0 = n[q - 2] + i.count1bits;
        if (s.part2_3_length <= h0)
          break;
        var d0 = new m(h0), M0 = l(r, i0, T, d0);
        h0 = d0.bits, !(s.part2_3_length <= h0) && (s.assign(i), s.part2_3_length = h0, s.region0_count = f[q - 2], s.region1_count = q - 2 - f[q - 2], s.table_select[0] = Y[q - 2], s.table_select[1] = J[q - 2], s.table_select[2] = M0);
      }
    }
    this.best_huffman_divide = function(E, i) {
      var s = new D(), r = i.l3_enc, n = z(7 + 15 + 1), f = z(7 + 15 + 1), Y = z(7 + 15 + 1), J = z(7 + 15 + 1);
      if (!(i.block_type == W.SHORT_TYPE && E.mode_gr == 1)) {
        s.assign(i), i.block_type == W.NORM_TYPE && (M(E, i, r, n, f, Y, J), p(
          E,
          s,
          i,
          r,
          n,
          f,
          Y,
          J
        ));
        var T = s.big_values;
        if (!(T == 0 || (r[T - 2] | r[T - 1]) > 1) && (T = i.count1 + 2, !(T > 576))) {
          s.assign(i), s.count1 = T;
          for (var q = 0, i0 = 0; T > s.big_values; T -= 4) {
            var h0 = ((r[T - 4] * 2 + r[T - 3]) * 2 + r[T - 2]) * 2 + r[T - 1];
            q += Q.t32l[h0], i0 += Q.t33l[h0];
          }
          if (s.big_values = T, s.count1table_select = 0, q > i0 && (q = i0, s.count1table_select = 1), s.count1bits = q, s.block_type == W.NORM_TYPE)
            p(
              E,
              s,
              i,
              r,
              n,
              f,
              Y,
              J
            );
          else {
            if (s.part2_3_length = q, q = E.scalefac_band.l[7 + 1], q > T && (q = T), q > 0) {
              var d0 = new m(s.part2_3_length);
              s.table_select[0] = l(r, 0, q, d0), s.part2_3_length = d0.bits;
            }
            if (T > q) {
              var d0 = new m(s.part2_3_length);
              s.table_select[1] = l(r, q, T, d0), s.part2_3_length = d0.bits;
            }
            i.part2_3_length > s.part2_3_length && i.assign(s);
          }
        }
      }
    };
    var H = [1, 1, 1, 1, 8, 2, 2, 2, 4, 4, 4, 8, 8, 8, 16, 16], B = [1, 2, 4, 8, 1, 2, 4, 8, 2, 4, 8, 2, 4, 8, 4, 8], I = [0, 0, 0, 0, 3, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4], v0 = [0, 1, 2, 3, 0, 1, 2, 3, 1, 2, 3, 1, 2, 3, 2, 3];
    f0.slen1_tab = I, f0.slen2_tab = v0;
    function b(E, i) {
      for (var s, r = i.tt[1][E], n = i.tt[0][E], f = 0; f < Q.scfsi_band.length - 1; f++) {
        for (s = Q.scfsi_band[f]; s < Q.scfsi_band[f + 1] && !(n.scalefac[s] != r.scalefac[s] && r.scalefac[s] >= 0); s++)
          ;
        if (s == Q.scfsi_band[f + 1]) {
          for (s = Q.scfsi_band[f]; s < Q.scfsi_band[f + 1]; s++)
            r.scalefac[s] = -1;
          i.scfsi[E][f] = 1;
        }
      }
      var Y = 0, J = 0;
      for (s = 0; s < 11; s++)
        r.scalefac[s] != -1 && (J++, Y < r.scalefac[s] && (Y = r.scalefac[s]));
      for (var T = 0, q = 0; s < W.SBPSY_l; s++)
        r.scalefac[s] != -1 && (q++, T < r.scalefac[s] && (T = r.scalefac[s]));
      for (var f = 0; f < 16; f++)
        if (Y < H[f] && T < B[f]) {
          var i0 = I[f] * J + v0[f] * q;
          r.part2_length > i0 && (r.part2_length = i0, r.scalefac_compress = f);
        }
    }
    this.best_scalefac_store = function(E, i, s, r) {
      var n = r.tt[i][s], f, Y, J, T, q = 0;
      for (J = 0, f = 0; f < n.sfbmax; f++) {
        var i0 = n.width[f];
        for (J += i0, T = -i0; T < 0 && n.l3_enc[T + J] == 0; T++)
          ;
        T == 0 && (n.scalefac[f] = q = -2);
      }
      if (n.scalefac_scale == 0 && n.preflag == 0) {
        var h0 = 0;
        for (f = 0; f < n.sfbmax; f++)
          n.scalefac[f] > 0 && (h0 |= n.scalefac[f]);
        if (!(h0 & 1) && h0 != 0) {
          for (f = 0; f < n.sfbmax; f++)
            n.scalefac[f] > 0 && (n.scalefac[f] >>= 1);
          n.scalefac_scale = q = 1;
        }
      }
      if (n.preflag == 0 && n.block_type != W.SHORT_TYPE && E.mode_gr == 2) {
        for (f = 11; f < W.SBPSY_l && !(n.scalefac[f] < A.pretab[f] && n.scalefac[f] != -2); f++)
          ;
        if (f == W.SBPSY_l) {
          for (f = 11; f < W.SBPSY_l; f++)
            n.scalefac[f] > 0 && (n.scalefac[f] -= A.pretab[f]);
          n.preflag = q = 1;
        }
      }
      for (Y = 0; Y < 4; Y++)
        r.scfsi[s][Y] = 0;
      for (E.mode_gr == 2 && i == 1 && r.tt[0][s].block_type != W.SHORT_TYPE && r.tt[1][s].block_type != W.SHORT_TYPE && (b(s, r), q = 0), f = 0; f < n.sfbmax; f++)
        n.scalefac[f] == -2 && (n.scalefac[f] = 0);
      q != 0 && (E.mode_gr == 2 ? this.scale_bitcount(n) : this.scale_bitcount_lsf(E, n));
    };
    function a(E, i) {
      for (var s = 0; s < i; ++s)
        if (E[s] < 0)
          return !1;
      return !0;
    }
    var S = [
      0,
      18,
      36,
      54,
      54,
      36,
      54,
      72,
      54,
      72,
      90,
      72,
      90,
      108,
      108,
      126
    ], L = [
      0,
      18,
      36,
      54,
      51,
      35,
      53,
      71,
      52,
      70,
      88,
      69,
      87,
      105,
      104,
      122
    ], V = [
      0,
      10,
      20,
      30,
      33,
      21,
      31,
      41,
      32,
      42,
      52,
      43,
      53,
      63,
      64,
      74
    ];
    this.scale_bitcount = function(E) {
      var i, s, r = 0, n = 0, f, Y = E.scalefac;
      if (u0(a(Y, E.sfbmax)), E.block_type == W.SHORT_TYPE)
        f = S, E.mixed_block_flag != 0 && (f = L);
      else if (f = V, E.preflag == 0) {
        for (s = 11; s < W.SBPSY_l && !(Y[s] < A.pretab[s]); s++)
          ;
        if (s == W.SBPSY_l)
          for (E.preflag = 1, s = 11; s < W.SBPSY_l; s++)
            Y[s] -= A.pretab[s];
      }
      for (s = 0; s < E.sfbdivide; s++)
        r < Y[s] && (r = Y[s]);
      for (; s < E.sfbmax; s++)
        n < Y[s] && (n = Y[s]);
      for (E.part2_length = g.LARGE_BITS, i = 0; i < 16; i++)
        r < H[i] && n < B[i] && E.part2_length > f[i] && (E.part2_length = f[i], E.scalefac_compress = i);
      return E.part2_length == g.LARGE_BITS;
    };
    var N = [
      [15, 15, 7, 7],
      [15, 15, 7, 0],
      [7, 3, 0, 0],
      [15, 31, 31, 0],
      [7, 7, 7, 0],
      [3, 3, 0, 0]
    ];
    this.scale_bitcount_lsf = function(E, i) {
      var s, r, n, f, Y, J, T, q, i0 = z(4), h0 = i.scalefac;
      for (i.preflag != 0 ? s = 2 : s = 0, T = 0; T < 4; T++)
        i0[T] = 0;
      if (i.block_type == W.SHORT_TYPE) {
        r = 1;
        var d0 = A.nr_of_sfb_block[s][r];
        for (q = 0, n = 0; n < 4; n++)
          for (f = d0[n] / 3, T = 0; T < f; T++, q++)
            for (Y = 0; Y < 3; Y++)
              h0[q * 3 + Y] > i0[n] && (i0[n] = h0[q * 3 + Y]);
      } else {
        r = 0;
        var d0 = A.nr_of_sfb_block[s][r];
        for (q = 0, n = 0; n < 4; n++)
          for (f = d0[n], T = 0; T < f; T++, q++)
            h0[q] > i0[n] && (i0[n] = h0[q]);
      }
      for (J = !1, n = 0; n < 4; n++)
        i0[n] > N[s][n] && (J = !0);
      if (!J) {
        var M0, R0, A0, w0;
        for (i.sfb_partition_table = A.nr_of_sfb_block[s][r], n = 0; n < 4; n++)
          i.slen[n] = P[i0[n]];
        switch (M0 = i.slen[0], R0 = i.slen[1], A0 = i.slen[2], w0 = i.slen[3], s) {
          case 0:
            i.scalefac_compress = (M0 * 5 + R0 << 4) + (A0 << 2) + w0;
            break;
          case 1:
            i.scalefac_compress = 400 + (M0 * 5 + R0 << 2) + A0;
            break;
          case 2:
            i.scalefac_compress = 500 + M0 * 3 + R0;
            break;
          default:
            Z.err.printf(`intensity stereo not implemented yet
`);
            break;
        }
      }
      if (!J)
        for (u0(i.sfb_partition_table != null), i.part2_length = 0, n = 0; n < 4; n++)
          i.part2_length += i.slen[n] * i.sfb_partition_table[n];
      return J;
    };
    var P = [
      0,
      1,
      2,
      2,
      3,
      3,
      3,
      3,
      4,
      4,
      4,
      4,
      4,
      4,
      4,
      4
    ];
    this.huffman_init = function(E) {
      for (var i = 2; i <= 576; i += 2) {
        for (var s = 0, r; E.scalefac_band.l[++s] < i; )
          ;
        for (r = O[s][0]; E.scalefac_band.l[r + 1] > i; )
          r--;
        for (r < 0 && (r = O[s][0]), E.bv_scf[i - 2] = r, r = O[s][1]; E.scalefac_band.l[r + E.bv_scf[i - 2] + 2] > i; )
          r--;
        r < 0 && (r = O[s][1]), E.bv_scf[i - 1] = r;
      }
    };
  }
  return Ee = f0, Ee;
}
var Be, sa;
function Ve() {
  if (sa)
    return Be;
  sa = 1;
  var w = Q0, Z = w.System, X = w.Arrays, z = w.new_byte, u0 = w.new_float_n, W = w.new_int, Q = w.assert, D = Oa(), g = He, f0 = t1(), A = ne;
  m.EQ = function(O, s0) {
    return Math.abs(O) > Math.abs(s0) ? Math.abs(O - s0) <= Math.abs(O) * 1e-6 : Math.abs(O - s0) <= Math.abs(s0) * 1e-6;
  }, m.NEQ = function(O, s0) {
    return !m.EQ(O, s0);
  };
  function m() {
    var O = Oe(), s0 = this, K = 32773, t0 = null, U = null, R = null, o = null;
    this.setModules = function(i, s, r, n) {
      t0 = i, U = s, R = r, o = n;
    };
    var u = null, d = 0, e = 0, l = 0;
    this.getframebits = function(i) {
      var s = i.internal_flags, r;
      s.bitrate_index != 0 ? r = g.bitrate_table[i.version][s.bitrate_index] : r = i.brate;
      var n = 0 | (i.version + 1) * 72e3 * r / i.out_samplerate + s.padding;
      return 8 * n;
    };
    function M(i) {
      Z.arraycopy(i.header[i.w_ptr].buf, 0, u, e, i.sideinfo_len), e += i.sideinfo_len, d += i.sideinfo_len * 8, i.w_ptr = i.w_ptr + 1 & A.MAX_HEADER_BUF - 1;
    }
    function p(i, s, r) {
      for (; r > 0; ) {
        var n;
        l == 0 && (l = 8, e++, Q(e < O.LAME_MAXMP3BUFFER), Q(i.header[i.w_ptr].write_timing >= d), i.header[i.w_ptr].write_timing == d && M(i), u[e] = 0), n = Math.min(r, l), r -= n, l -= n, u[e] |= s >> r << l, d += n;
      }
    }
    function H(i, s, r) {
      for (; r > 0; ) {
        var n;
        l == 0 && (l = 8, e++, Q(e < O.LAME_MAXMP3BUFFER), u[e] = 0), n = Math.min(r, l), r -= n, l -= n, u[e] |= s >> r << l, d += n;
      }
    }
    function B(i, s) {
      var r = i.internal_flags, n;
      if (s >= 8 && (p(r, 76, 8), s -= 8), s >= 8 && (p(r, 65, 8), s -= 8), s >= 8 && (p(r, 77, 8), s -= 8), s >= 8 && (p(r, 69, 8), s -= 8), s >= 32) {
        var f = R.getLameShortVersion();
        if (s >= 32)
          for (n = 0; n < f.length && s >= 8; ++n)
            s -= 8, p(r, f.charAt(n), 8);
      }
      for (; s >= 1; s -= 1)
        p(r, r.ancillary_flag, 1), r.ancillary_flag ^= i.disable_reservoir ? 0 : 1;
    }
    function I(i, s, r) {
      for (var n = i.header[i.h_ptr].ptr; r > 0; ) {
        var f = Math.min(r, 8 - (n & 7));
        r -= f, i.header[i.h_ptr].buf[n >> 3] |= s >> r << 8 - (n & 7) - f, n += f;
      }
      i.header[i.h_ptr].ptr = n;
    }
    function v0(i, s) {
      i <<= 8;
      for (var r = 0; r < 8; r++)
        i <<= 1, s <<= 1, (s ^ i) & 65536 && (s ^= K);
      return s;
    }
    this.CRC_writeheader = function(i, s) {
      var r = 65535;
      r = v0(s[2] & 255, r), r = v0(s[3] & 255, r);
      for (var n = 6; n < i.sideinfo_len; n++)
        r = v0(s[n] & 255, r);
      s[4] = byte(r >> 8), s[5] = byte(r & 255);
    };
    function b(i, s) {
      var r = i.internal_flags, n, f, Y;
      if (n = r.l3_side, r.header[r.h_ptr].ptr = 0, X.fill(r.header[r.h_ptr].buf, 0, r.sideinfo_len, 0), i.out_samplerate < 16e3 ? I(r, 4094, 12) : I(r, 4095, 12), I(r, i.version, 1), I(r, 4 - 3, 2), I(r, i.error_protection ? 0 : 1, 1), I(r, r.bitrate_index, 4), I(r, r.samplerate_index, 2), I(r, r.padding, 1), I(r, i.extension, 1), I(r, i.mode.ordinal(), 2), I(r, r.mode_ext, 2), I(r, i.copyright, 1), I(r, i.original, 1), I(r, i.emphasis, 2), i.error_protection && I(r, 0, 16), i.version == 1) {
        for (Q(n.main_data_begin >= 0), I(r, n.main_data_begin, 9), r.channels_out == 2 ? I(r, n.private_bits, 3) : I(r, n.private_bits, 5), Y = 0; Y < r.channels_out; Y++) {
          var J;
          for (J = 0; J < 4; J++)
            I(r, n.scfsi[Y][J], 1);
        }
        for (f = 0; f < 2; f++)
          for (Y = 0; Y < r.channels_out; Y++) {
            var T = n.tt[f][Y];
            I(r, T.part2_3_length + T.part2_length, 12), I(r, T.big_values / 2, 9), I(r, T.global_gain, 8), I(r, T.scalefac_compress, 4), T.block_type != f0.NORM_TYPE ? (I(r, 1, 1), I(r, T.block_type, 2), I(r, T.mixed_block_flag, 1), T.table_select[0] == 14 && (T.table_select[0] = 16), I(r, T.table_select[0], 5), T.table_select[1] == 14 && (T.table_select[1] = 16), I(r, T.table_select[1], 5), I(r, T.subblock_gain[0], 3), I(r, T.subblock_gain[1], 3), I(r, T.subblock_gain[2], 3)) : (I(r, 0, 1), T.table_select[0] == 14 && (T.table_select[0] = 16), I(r, T.table_select[0], 5), T.table_select[1] == 14 && (T.table_select[1] = 16), I(r, T.table_select[1], 5), T.table_select[2] == 14 && (T.table_select[2] = 16), I(r, T.table_select[2], 5), Q(0 <= T.region0_count && T.region0_count < 16), Q(0 <= T.region1_count && T.region1_count < 8), I(r, T.region0_count, 4), I(r, T.region1_count, 3)), I(r, T.preflag, 1), I(r, T.scalefac_scale, 1), I(r, T.count1table_select, 1);
          }
      } else
        for (Q(n.main_data_begin >= 0), I(r, n.main_data_begin, 8), I(r, n.private_bits, r.channels_out), f = 0, Y = 0; Y < r.channels_out; Y++) {
          var T = n.tt[f][Y];
          I(r, T.part2_3_length + T.part2_length, 12), I(r, T.big_values / 2, 9), I(r, T.global_gain, 8), I(r, T.scalefac_compress, 9), T.block_type != f0.NORM_TYPE ? (I(r, 1, 1), I(r, T.block_type, 2), I(r, T.mixed_block_flag, 1), T.table_select[0] == 14 && (T.table_select[0] = 16), I(r, T.table_select[0], 5), T.table_select[1] == 14 && (T.table_select[1] = 16), I(r, T.table_select[1], 5), I(r, T.subblock_gain[0], 3), I(r, T.subblock_gain[1], 3), I(r, T.subblock_gain[2], 3)) : (I(r, 0, 1), T.table_select[0] == 14 && (T.table_select[0] = 16), I(r, T.table_select[0], 5), T.table_select[1] == 14 && (T.table_select[1] = 16), I(r, T.table_select[1], 5), T.table_select[2] == 14 && (T.table_select[2] = 16), I(r, T.table_select[2], 5), Q(0 <= T.region0_count && T.region0_count < 16), Q(0 <= T.region1_count && T.region1_count < 8), I(r, T.region0_count, 4), I(r, T.region1_count, 3)), I(r, T.scalefac_scale, 1), I(r, T.count1table_select, 1);
        }
      i.error_protection && CRC_writeheader(r, r.header[r.h_ptr].buf);
      {
        var q = r.h_ptr;
        Q(r.header[q].ptr == r.sideinfo_len * 8), r.h_ptr = q + 1 & A.MAX_HEADER_BUF - 1, r.header[r.h_ptr].write_timing = r.header[q].write_timing + s, r.h_ptr == r.w_ptr && Z.err.println(`Error: MAX_HEADER_BUF too small in bitstream.c 
`);
      }
    }
    function a(i, s) {
      var r = g.ht[s.count1table_select + 32], n, f = 0, Y = s.big_values, J = s.big_values;
      for (Q(s.count1table_select < 2), n = (s.count1 - s.big_values) / 4; n > 0; --n) {
        var T = 0, q = 0, i0;
        i0 = s.l3_enc[Y + 0], i0 != 0 && (q += 8, s.xr[J + 0] < 0 && T++), i0 = s.l3_enc[Y + 1], i0 != 0 && (q += 4, T *= 2, s.xr[J + 1] < 0 && T++), i0 = s.l3_enc[Y + 2], i0 != 0 && (q += 2, T *= 2, s.xr[J + 2] < 0 && T++), i0 = s.l3_enc[Y + 3], i0 != 0 && (q++, T *= 2, s.xr[J + 3] < 0 && T++), Y += 4, J += 4, p(i, T + r.table[q], r.hlen[q]), f += r.hlen[q];
      }
      return f;
    }
    function S(i, s, r, n, f) {
      var Y = g.ht[s], J = 0;
      if (s == 0)
        return J;
      for (var T = r; T < n; T += 2) {
        var q = 0, i0 = 0, h0 = Y.xlen, d0 = Y.xlen, M0 = 0, R0 = f.l3_enc[T], A0 = f.l3_enc[T + 1];
        if (R0 != 0 && (f.xr[T] < 0 && M0++, q--), s > 15) {
          if (R0 > 14) {
            var w0 = R0 - 15;
            Q(w0 <= Y.linmax), M0 |= w0 << 1, i0 = h0, R0 = 15;
          }
          if (A0 > 14) {
            var $0 = A0 - 15;
            Q($0 <= Y.linmax), M0 <<= h0, M0 |= $0, i0 += h0, A0 = 15;
          }
          d0 = 16;
        }
        A0 != 0 && (M0 <<= 1, f.xr[T + 1] < 0 && M0++, q--), R0 = R0 * d0 + A0, i0 -= q, q += Y.hlen[R0], p(i, Y.table[R0], q), p(i, M0, i0), J += q + i0;
      }
      return J;
    }
    function L(i, s) {
      var r = 3 * i.scalefac_band.s[3];
      r > s.big_values && (r = s.big_values);
      var n = S(i, s.table_select[0], 0, r, s);
      return n += S(
        i,
        s.table_select[1],
        r,
        s.big_values,
        s
      ), n;
    }
    function V(i, s) {
      var r, n, f, Y;
      r = s.big_values;
      var J = s.region0_count + 1;
      return Q(J < i.scalefac_band.l.length), f = i.scalefac_band.l[J], J += s.region1_count + 1, Q(J < i.scalefac_band.l.length), Y = i.scalefac_band.l[J], f > r && (f = r), Y > r && (Y = r), n = S(i, s.table_select[0], 0, f, s), n += S(
        i,
        s.table_select[1],
        f,
        Y,
        s
      ), n += S(
        i,
        s.table_select[2],
        Y,
        r,
        s
      ), n;
    }
    function N(i) {
      var s, r, n, f, Y = 0, J = i.internal_flags, T = J.l3_side;
      if (i.version == 1)
        for (s = 0; s < 2; s++)
          for (r = 0; r < J.channels_out; r++) {
            var q = T.tt[s][r], i0 = D.slen1_tab[q.scalefac_compress], h0 = D.slen2_tab[q.scalefac_compress];
            for (f = 0, n = 0; n < q.sfbdivide; n++)
              q.scalefac[n] != -1 && (p(J, q.scalefac[n], i0), f += i0);
            for (; n < q.sfbmax; n++)
              q.scalefac[n] != -1 && (p(J, q.scalefac[n], h0), f += h0);
            Q(f == q.part2_length), q.block_type == f0.SHORT_TYPE ? f += L(J, q) : f += V(J, q), f += a(J, q), Q(f == q.part2_3_length + q.part2_length), Y += f;
          }
      else
        for (s = 0, r = 0; r < J.channels_out; r++) {
          var q = T.tt[s][r], d0, M0, R0 = 0;
          if (Q(q.sfb_partition_table != null), f = 0, n = 0, M0 = 0, q.block_type == f0.SHORT_TYPE) {
            for (; M0 < 4; M0++) {
              var A0 = q.sfb_partition_table[M0] / 3, w0 = q.slen[M0];
              for (d0 = 0; d0 < A0; d0++, n++)
                p(
                  J,
                  Math.max(q.scalefac[n * 3 + 0], 0),
                  w0
                ), p(
                  J,
                  Math.max(q.scalefac[n * 3 + 1], 0),
                  w0
                ), p(
                  J,
                  Math.max(q.scalefac[n * 3 + 2], 0),
                  w0
                ), R0 += 3 * w0;
            }
            f += L(J, q);
          } else {
            for (; M0 < 4; M0++) {
              var A0 = q.sfb_partition_table[M0], w0 = q.slen[M0];
              for (d0 = 0; d0 < A0; d0++, n++)
                p(J, Math.max(q.scalefac[n], 0), w0), R0 += w0;
            }
            f += V(J, q);
          }
          f += a(J, q), Q(f == q.part2_3_length), Q(R0 == q.part2_length), Y += R0 + f;
        }
      return Y;
    }
    function P() {
      this.total = 0;
    }
    function E(i, s) {
      var r = i.internal_flags, n, f, Y, J, T;
      return T = r.w_ptr, J = r.h_ptr - 1, J == -1 && (J = A.MAX_HEADER_BUF - 1), n = r.header[J].write_timing - d, s.total = n, n >= 0 && (f = 1 + J - T, J < T && (f = 1 + J - T + A.MAX_HEADER_BUF), n -= f * 8 * r.sideinfo_len), Y = s0.getframebits(i), n += Y, s.total += Y, s.total % 8 != 0 ? s.total = 1 + s.total / 8 : s.total = s.total / 8, s.total += e + 1, n < 0 && Z.err.println(`strange error flushing buffer ... 
`), n;
    }
    this.flush_bitstream = function(i) {
      var s = i.internal_flags, r, n, f = s.h_ptr - 1;
      if (f == -1 && (f = A.MAX_HEADER_BUF - 1), r = s.l3_side, !((n = E(i, new P())) < 0)) {
        if (B(i, n), Q(s.header[f].write_timing + this.getframebits(i) == d), s.ResvSize = 0, r.main_data_begin = 0, s.findReplayGain) {
          var Y = t0.GetTitleGain(s.rgdata);
          Q(NEQ(Y, GainAnalysis.GAIN_NOT_ENOUGH_SAMPLES)), s.RadioGain = Math.floor(Y * 10 + 0.5) | 0;
        }
        s.findPeakSample && (s.noclipGainChange = Math.ceil(Math.log10(s.PeakSample / 32767) * 20 * 10) | 0, s.noclipGainChange > 0 && (EQ(i.scale, 1) || EQ(i.scale, 0)) ? s.noclipScale = Math.floor(32767 / s.PeakSample * 100) / 100 : s.noclipScale = -1);
      }
    }, this.add_dummy_byte = function(i, s, r) {
      for (var n = i.internal_flags, f; r-- > 0; )
        for (H(n, s, 8), f = 0; f < A.MAX_HEADER_BUF; ++f)
          n.header[f].write_timing += 8;
    }, this.format_bitstream = function(i) {
      var s = i.internal_flags, r;
      r = s.l3_side;
      var n = this.getframebits(i);
      B(i, r.resvDrain_pre), b(i, n);
      var f = 8 * s.sideinfo_len;
      if (f += N(i), B(i, r.resvDrain_post), f += r.resvDrain_post, r.main_data_begin += (n - f) / 8, E(i, new P()) != s.ResvSize && Z.err.println("Internal buffer inconsistency. flushbits <> ResvSize"), r.main_data_begin * 8 != s.ResvSize && (Z.err.printf(
        `bit reservoir error: 
l3_side.main_data_begin: %d 
Resvoir size:             %d 
resv drain (post)         %d 
resv drain (pre)          %d 
header and sideinfo:      %d 
data bits:                %d 
total bits:               %d (remainder: %d) 
bitsperframe:             %d 
`,
        8 * r.main_data_begin,
        s.ResvSize,
        r.resvDrain_post,
        r.resvDrain_pre,
        8 * s.sideinfo_len,
        f - r.resvDrain_post - 8 * s.sideinfo_len,
        f,
        f % 8,
        n
      ), Z.err.println("This is a fatal error.  It has several possible causes:"), Z.err.println("90%%  LAME compiled with buggy version of gcc using advanced optimizations"), Z.err.println(" 9%%  Your system is overclocked"), Z.err.println(" 1%%  bug in LAME encoding library"), s.ResvSize = r.main_data_begin * 8), d > 1e9) {
        var Y;
        for (Y = 0; Y < A.MAX_HEADER_BUF; ++Y)
          s.header[Y].write_timing -= d;
        d = 0;
      }
      return 0;
    }, this.copy_buffer = function(i, s, r, n, f) {
      var Y = e + 1;
      if (Y <= 0)
        return 0;
      if (n != 0 && Y > n)
        return -1;
      if (Z.arraycopy(u, 0, s, r, Y), e = -1, l = 0, f != 0) {
        var J = W(1);
        if (J[0] = i.nMusicCRC, o.updateMusicCRC(J, s, r, Y), i.nMusicCRC = J[0], Y > 0 && (i.VBR_seek_table.nBytesWritten += Y), i.decode_on_the_fly) {
          for (var T = u0([2, 1152]), q = Y, i0 = -1, h0; i0 != 0; )
            if (i0 = U.hip_decode1_unclipped(
              i.hip,
              s,
              r,
              q,
              T[0],
              T[1]
            ), q = 0, i0 == -1 && (i0 = 0), i0 > 0) {
              if (i.findPeakSample) {
                for (h0 = 0; h0 < i0; h0++)
                  T[0][h0] > i.PeakSample ? i.PeakSample = T[0][h0] : -T[0][h0] > i.PeakSample && (i.PeakSample = -T[0][h0]);
                if (i.channels_out > 1)
                  for (h0 = 0; h0 < i0; h0++)
                    T[1][h0] > i.PeakSample ? i.PeakSample = T[1][h0] : -T[1][h0] > i.PeakSample && (i.PeakSample = -T[1][h0]);
              }
              if (i.findReplayGain && t0.AnalyzeSamples(
                i.rgdata,
                T[0],
                0,
                T[1],
                0,
                i0,
                i.channels_out
              ) == GainAnalysis.GAIN_ANALYSIS_ERROR)
                return -6;
            }
        }
      }
      return Y;
    }, this.init_bit_stream_w = function(i) {
      u = z(O.LAME_MAXMP3BUFFER), i.h_ptr = i.w_ptr = 0, i.header[i.h_ptr].write_timing = 0, e = -1, l = 0, d = 0;
    };
  }
  return Be = m, Be;
}
var Te, ia;
function Oe() {
  if (ia)
    return Te;
  ia = 1;
  var w = Q0, Z = w.System, X = w.VbrMode, z = w.ShortBlock, u0 = w.new_float, W = w.new_int_n, Q = w.new_short_n, D = w.assert, g = Qa, f0 = za, A = ne, m = x2, O = E2, s0 = N2, K = Ve(), t0 = He, U = t1();
  function R() {
    var o = j1, u = this, d = 128 * 1024;
    R.V9 = 410, R.V8 = 420, R.V7 = 430, R.V6 = 440, R.V5 = 450, R.V4 = 460, R.V3 = 470, R.V2 = 480, R.V1 = 490, R.V0 = 500, R.R3MIX = 1e3, R.STANDARD = 1001, R.EXTREME = 1002, R.INSANE = 1003, R.STANDARD_FAST = 1004, R.EXTREME_FAST = 1005, R.MEDIUM = 1006, R.MEDIUM_FAST = 1007;
    var e = 16384 + d;
    R.LAME_MAXMP3BUFFER = e;
    var l, M, p, H, B, I = new g(), v0, b, a;
    this.enc = new U(), this.setModules = function(t, _, S0, E0, V0, H0, y0, T0, F0) {
      l = t, M = _, p = S0, H = E0, B = V0, v0 = H0, b = T0, a = F0, this.enc.setModules(M, I, H, v0);
    };
    function S() {
      this.mask_adjust = 0, this.mask_adjust_short = 0, this.bo_l_weight = u0(U.SBMAX_l), this.bo_s_weight = u0(U.SBMAX_s);
    }
    function L() {
      this.lowerlimit = 0;
    }
    function V(t, _) {
      this.lowpass = _;
    }
    var N = 4294479419;
    function P(t) {
      var _;
      return t.class_id = N, _ = t.internal_flags = new A(), t.mode = o.NOT_SET, t.original = 1, t.in_samplerate = 44100, t.num_channels = 2, t.num_samples = -1, t.bWriteVbrTag = !0, t.quality = -1, t.short_blocks = null, _.subblock_gain = -1, t.lowpassfreq = 0, t.highpassfreq = 0, t.lowpasswidth = -1, t.highpasswidth = -1, t.VBR = X.vbr_off, t.VBR_q = 4, t.ATHcurve = -1, t.VBR_mean_bitrate_kbps = 128, t.VBR_min_bitrate_kbps = 0, t.VBR_max_bitrate_kbps = 0, t.VBR_hard_min = 0, _.VBR_min_bitrate = 1, _.VBR_max_bitrate = 13, t.quant_comp = -1, t.quant_comp_short = -1, t.msfix = -1, _.resample_ratio = 1, _.OldValue[0] = 180, _.OldValue[1] = 180, _.CurrentStep[0] = 4, _.CurrentStep[1] = 4, _.masking_lower = 1, _.nsPsy.attackthre = -1, _.nsPsy.attackthre_s = -1, t.scale = -1, t.athaa_type = -1, t.ATHtype = -1, t.athaa_loudapprox = -1, t.athaa_sensitivity = 0, t.useTemporal = null, t.interChRatio = -1, _.mf_samples_to_encode = U.ENCDELAY + U.POSTDELAY, t.encoder_padding = 0, _.mf_size = U.ENCDELAY - U.MDCTDELAY, t.findReplayGain = !1, t.decode_on_the_fly = !1, _.decode_on_the_fly = !1, _.findReplayGain = !1, _.findPeakSample = !1, _.RadioGain = 0, _.AudiophileGain = 0, _.noclipGainChange = 0, _.noclipScale = -1, t.preset = 0, t.write_id3tag_automatic = !0, 0;
    }
    this.lame_init = function() {
      var t = new f0();
      return P(t), t.lame_allocated_gfp = 1, t;
    };
    function E(t) {
      return t > 1 ? 0 : t <= 0 ? 1 : Math.cos(Math.PI / 2 * t);
    }
    this.nearestBitrateFullIndex = function(t) {
      var _ = [
        8,
        16,
        24,
        32,
        40,
        48,
        56,
        64,
        80,
        96,
        112,
        128,
        160,
        192,
        224,
        256,
        320
      ], S0 = 0, E0 = 0, V0 = 0, H0 = 0;
      H0 = _[16], V0 = 16, E0 = _[16], S0 = 16;
      for (var y0 = 0; y0 < 16; y0++)
        if (Math.max(t, _[y0 + 1]) != t) {
          H0 = _[y0 + 1], V0 = y0 + 1, E0 = _[y0], S0 = y0;
          break;
        }
      return H0 - t > t - E0 ? S0 : V0;
    };
    function i(t, _) {
      var S0 = 44100;
      return _ >= 48e3 ? S0 = 48e3 : _ >= 44100 ? S0 = 44100 : _ >= 32e3 ? S0 = 32e3 : _ >= 24e3 ? S0 = 24e3 : _ >= 22050 ? S0 = 22050 : _ >= 16e3 ? S0 = 16e3 : _ >= 12e3 ? S0 = 12e3 : _ >= 11025 ? S0 = 11025 : _ >= 8e3 && (S0 = 8e3), t == -1 ? S0 : (t <= 15960 && (S0 = 44100), t <= 15250 && (S0 = 32e3), t <= 11220 && (S0 = 24e3), t <= 9970 && (S0 = 22050), t <= 7230 && (S0 = 16e3), t <= 5420 && (S0 = 12e3), t <= 4510 && (S0 = 11025), t <= 3970 && (S0 = 8e3), _ < S0 ? _ > 44100 ? 48e3 : _ > 32e3 ? 44100 : _ > 24e3 ? 32e3 : _ > 22050 ? 24e3 : _ > 16e3 ? 22050 : _ > 12e3 ? 16e3 : _ > 11025 ? 12e3 : _ > 8e3 ? 11025 : 8e3 : S0);
    }
    function s(t, _) {
      switch (t) {
        case 44100:
          return _.version = 1, 0;
        case 48e3:
          return _.version = 1, 1;
        case 32e3:
          return _.version = 1, 2;
        case 22050:
          return _.version = 0, 0;
        case 24e3:
          return _.version = 0, 1;
        case 16e3:
          return _.version = 0, 2;
        case 11025:
          return _.version = 0, 0;
        case 12e3:
          return _.version = 0, 1;
        case 8e3:
          return _.version = 0, 2;
        default:
          return _.version = 0, -1;
      }
    }
    function r(t, _, S0) {
      S0 < 16e3 && (_ = 2);
      for (var E0 = t0.bitrate_table[_][1], V0 = 2; V0 <= 14; V0++)
        t0.bitrate_table[_][V0] > 0 && Math.abs(t0.bitrate_table[_][V0] - t) < Math.abs(E0 - t) && (E0 = t0.bitrate_table[_][V0]);
      return E0;
    }
    function n(t, _, S0) {
      S0 < 16e3 && (_ = 2);
      for (var E0 = 0; E0 <= 14; E0++)
        if (t0.bitrate_table[_][E0] > 0 && t0.bitrate_table[_][E0] == t)
          return E0;
      return -1;
    }
    function f(t, _) {
      var S0 = [
        new V(8, 2e3),
        new V(16, 3700),
        new V(24, 3900),
        new V(32, 5500),
        new V(40, 7e3),
        new V(48, 7500),
        new V(56, 1e4),
        new V(64, 11e3),
        new V(80, 13500),
        new V(96, 15100),
        new V(112, 15600),
        new V(128, 17e3),
        new V(160, 17500),
        new V(192, 18600),
        new V(224, 19400),
        new V(256, 19700),
        new V(320, 20500)
      ], E0 = u.nearestBitrateFullIndex(_);
      t.lowerlimit = S0[E0].lowpass;
    }
    function Y(t) {
      var _ = t.internal_flags, S0 = 32, E0 = -1;
      if (_.lowpass1 > 0) {
        for (var V0 = 999, H0 = 0; H0 <= 31; H0++) {
          var y0 = H0 / 31;
          y0 >= _.lowpass2 && (S0 = Math.min(S0, H0)), _.lowpass1 < y0 && y0 < _.lowpass2 && (V0 = Math.min(V0, H0));
        }
        V0 == 999 ? _.lowpass1 = (S0 - 0.75) / 31 : _.lowpass1 = (V0 - 0.75) / 31, _.lowpass2 = S0 / 31;
      }
      if (_.highpass2 > 0 && _.highpass2 < 0.9 * (0.75 / 31) && (_.highpass1 = 0, _.highpass2 = 0, Z.err.println(`Warning: highpass filter disabled.  highpass frequency too small
`)), _.highpass2 > 0) {
        for (var T0 = -1, H0 = 0; H0 <= 31; H0++) {
          var y0 = H0 / 31;
          y0 <= _.highpass1 && (E0 = Math.max(E0, H0)), _.highpass1 < y0 && y0 < _.highpass2 && (T0 = Math.max(T0, H0));
        }
        _.highpass1 = E0 / 31, T0 == -1 ? _.highpass2 = (E0 + 0.75) / 31 : _.highpass2 = (T0 + 0.75) / 31;
      }
      for (var H0 = 0; H0 < 32; H0++) {
        var F0, I0, y0 = H0 / 31;
        _.highpass2 > _.highpass1 ? F0 = E((_.highpass2 - y0) / (_.highpass2 - _.highpass1 + 1e-20)) : F0 = 1, _.lowpass2 > _.lowpass1 ? I0 = E((y0 - _.lowpass1) / (_.lowpass2 - _.lowpass1 + 1e-20)) : I0 = 1, _.amp_filter[H0] = F0 * I0;
      }
    }
    function J(t) {
      var _ = t.internal_flags;
      switch (t.quality) {
        default:
        case 9:
          _.psymodel = 0, _.noise_shaping = 0, _.noise_shaping_amp = 0, _.noise_shaping_stop = 0, _.use_best_huffman = 0, _.full_outer_loop = 0;
          break;
        case 8:
          t.quality = 7;
        case 7:
          _.psymodel = 1, _.noise_shaping = 0, _.noise_shaping_amp = 0, _.noise_shaping_stop = 0, _.use_best_huffman = 0, _.full_outer_loop = 0;
          break;
        case 6:
          _.psymodel = 1, _.noise_shaping == 0 && (_.noise_shaping = 1), _.noise_shaping_amp = 0, _.noise_shaping_stop = 0, _.subblock_gain == -1 && (_.subblock_gain = 1), _.use_best_huffman = 0, _.full_outer_loop = 0;
          break;
        case 5:
          _.psymodel = 1, _.noise_shaping == 0 && (_.noise_shaping = 1), _.noise_shaping_amp = 0, _.noise_shaping_stop = 0, _.subblock_gain == -1 && (_.subblock_gain = 1), _.use_best_huffman = 0, _.full_outer_loop = 0;
          break;
        case 4:
          _.psymodel = 1, _.noise_shaping == 0 && (_.noise_shaping = 1), _.noise_shaping_amp = 0, _.noise_shaping_stop = 0, _.subblock_gain == -1 && (_.subblock_gain = 1), _.use_best_huffman = 1, _.full_outer_loop = 0;
          break;
        case 3:
          _.psymodel = 1, _.noise_shaping == 0 && (_.noise_shaping = 1), _.noise_shaping_amp = 1, _.noise_shaping_stop = 1, _.subblock_gain == -1 && (_.subblock_gain = 1), _.use_best_huffman = 1, _.full_outer_loop = 0;
          break;
        case 2:
          _.psymodel = 1, _.noise_shaping == 0 && (_.noise_shaping = 1), _.substep_shaping == 0 && (_.substep_shaping = 2), _.noise_shaping_amp = 1, _.noise_shaping_stop = 1, _.subblock_gain == -1 && (_.subblock_gain = 1), _.use_best_huffman = 1, _.full_outer_loop = 0;
          break;
        case 1:
          _.psymodel = 1, _.noise_shaping == 0 && (_.noise_shaping = 1), _.substep_shaping == 0 && (_.substep_shaping = 2), _.noise_shaping_amp = 2, _.noise_shaping_stop = 1, _.subblock_gain == -1 && (_.subblock_gain = 1), _.use_best_huffman = 1, _.full_outer_loop = 0;
          break;
        case 0:
          _.psymodel = 1, _.noise_shaping == 0 && (_.noise_shaping = 1), _.substep_shaping == 0 && (_.substep_shaping = 2), _.noise_shaping_amp = 2, _.noise_shaping_stop = 1, _.subblock_gain == -1 && (_.subblock_gain = 1), _.use_best_huffman = 1, _.full_outer_loop = 0;
          break;
      }
    }
    function T(t) {
      var _ = t.internal_flags;
      t.frameNum = 0, t.write_id3tag_automatic && b.id3tag_write_v2(t), _.bitrate_stereoMode_Hist = W([16, 4 + 1]), _.bitrate_blockType_Hist = W([16, 4 + 1 + 1]), _.PeakSample = 0, t.bWriteVbrTag && v0.InitVbrTag(t);
    }
    this.lame_init_params = function(t) {
      var _ = t.internal_flags;
      if (_.Class_ID = 0, _.ATH == null && (_.ATH = new m()), _.PSY == null && (_.PSY = new S()), _.rgdata == null && (_.rgdata = new O()), _.channels_in = t.num_channels, _.channels_in == 1 && (t.mode = o.MONO), _.channels_out = t.mode == o.MONO ? 1 : 2, _.mode_ext = U.MPG_MD_MS_LR, t.mode == o.MONO && (t.force_ms = !1), t.VBR == X.vbr_off && t.VBR_mean_bitrate_kbps != 128 && t.brate == 0 && (t.brate = t.VBR_mean_bitrate_kbps), t.VBR == X.vbr_off || t.VBR == X.vbr_mtrh || t.VBR == X.vbr_mt || (t.free_format = !1), t.VBR == X.vbr_off && t.brate == 0 && K.EQ(t.compression_ratio, 0) && (t.compression_ratio = 11.025), t.VBR == X.vbr_off && t.compression_ratio > 0 && (t.out_samplerate == 0 && (t.out_samplerate = map2MP3Frequency(int(0.97 * t.in_samplerate))), t.brate = 0 | t.out_samplerate * 16 * _.channels_out / (1e3 * t.compression_ratio), _.samplerate_index = s(t.out_samplerate, t), t.free_format || (t.brate = r(
        t.brate,
        t.version,
        t.out_samplerate
      ))), t.out_samplerate != 0 && (t.out_samplerate < 16e3 ? (t.VBR_mean_bitrate_kbps = Math.max(
        t.VBR_mean_bitrate_kbps,
        8
      ), t.VBR_mean_bitrate_kbps = Math.min(
        t.VBR_mean_bitrate_kbps,
        64
      )) : t.out_samplerate < 32e3 ? (t.VBR_mean_bitrate_kbps = Math.max(
        t.VBR_mean_bitrate_kbps,
        8
      ), t.VBR_mean_bitrate_kbps = Math.min(
        t.VBR_mean_bitrate_kbps,
        160
      )) : (t.VBR_mean_bitrate_kbps = Math.max(
        t.VBR_mean_bitrate_kbps,
        32
      ), t.VBR_mean_bitrate_kbps = Math.min(
        t.VBR_mean_bitrate_kbps,
        320
      ))), t.lowpassfreq == 0) {
        var S0 = 16e3;
        switch (t.VBR) {
          case X.vbr_off: {
            var E0 = new L();
            f(E0, t.brate), S0 = E0.lowerlimit;
            break;
          }
          case X.vbr_abr: {
            var E0 = new L();
            f(E0, t.VBR_mean_bitrate_kbps), S0 = E0.lowerlimit;
            break;
          }
          case X.vbr_rh: {
            var V0 = [
              19500,
              19e3,
              18600,
              18e3,
              17500,
              16e3,
              15600,
              14900,
              12500,
              1e4,
              3950
            ];
            if (0 <= t.VBR_q && t.VBR_q <= 9) {
              var H0 = V0[t.VBR_q], y0 = V0[t.VBR_q + 1], T0 = t.VBR_q_frac;
              S0 = linear_int(H0, y0, T0);
            } else
              S0 = 19500;
            break;
          }
          default: {
            var V0 = [
              19500,
              19e3,
              18500,
              18e3,
              17500,
              16500,
              15500,
              14500,
              12500,
              9500,
              3950
            ];
            if (0 <= t.VBR_q && t.VBR_q <= 9) {
              var H0 = V0[t.VBR_q], y0 = V0[t.VBR_q + 1], T0 = t.VBR_q_frac;
              S0 = linear_int(H0, y0, T0);
            } else
              S0 = 19500;
          }
        }
        t.mode == o.MONO && (t.VBR == X.vbr_off || t.VBR == X.vbr_abr) && (S0 *= 1.5), t.lowpassfreq = S0 | 0;
      }
      if (t.out_samplerate == 0 && (2 * t.lowpassfreq > t.in_samplerate && (t.lowpassfreq = t.in_samplerate / 2), t.out_samplerate = i(
        t.lowpassfreq | 0,
        t.in_samplerate
      )), t.lowpassfreq = Math.min(20500, t.lowpassfreq), t.lowpassfreq = Math.min(t.out_samplerate / 2, t.lowpassfreq), t.VBR == X.vbr_off && (t.compression_ratio = t.out_samplerate * 16 * _.channels_out / (1e3 * t.brate)), t.VBR == X.vbr_abr && (t.compression_ratio = t.out_samplerate * 16 * _.channels_out / (1e3 * t.VBR_mean_bitrate_kbps)), t.bWriteVbrTag || (t.findReplayGain = !1, t.decode_on_the_fly = !1, _.findPeakSample = !1), _.findReplayGain = t.findReplayGain, _.decode_on_the_fly = t.decode_on_the_fly, _.decode_on_the_fly && (_.findPeakSample = !0), _.findReplayGain && l.InitGainAnalysis(_.rgdata, t.out_samplerate) == GainAnalysis.INIT_GAIN_ANALYSIS_ERROR)
        return t.internal_flags = null, -6;
      switch (_.decode_on_the_fly && !t.decode_only && (_.hip != null && a.hip_decode_exit(_.hip), _.hip = a.hip_decode_init()), _.mode_gr = t.out_samplerate <= 24e3 ? 1 : 2, t.framesize = 576 * _.mode_gr, t.encoder_delay = U.ENCDELAY, _.resample_ratio = t.in_samplerate / t.out_samplerate, t.VBR) {
        case X.vbr_mt:
        case X.vbr_rh:
        case X.vbr_mtrh:
          {
            var F0 = [
              5.7,
              6.5,
              7.3,
              8.2,
              10,
              11.9,
              13,
              14,
              15,
              16.5
            ];
            t.compression_ratio = F0[t.VBR_q];
          }
          break;
        case X.vbr_abr:
          t.compression_ratio = t.out_samplerate * 16 * _.channels_out / (1e3 * t.VBR_mean_bitrate_kbps);
          break;
        default:
          t.compression_ratio = t.out_samplerate * 16 * _.channels_out / (1e3 * t.brate);
          break;
      }
      if (t.mode == o.NOT_SET && (t.mode = o.JOINT_STEREO), t.highpassfreq > 0 ? (_.highpass1 = 2 * t.highpassfreq, t.highpasswidth >= 0 ? _.highpass2 = 2 * (t.highpassfreq + t.highpasswidth) : _.highpass2 = (1 + 0) * 2 * t.highpassfreq, _.highpass1 /= t.out_samplerate, _.highpass2 /= t.out_samplerate) : (_.highpass1 = 0, _.highpass2 = 0), t.lowpassfreq > 0 ? (_.lowpass2 = 2 * t.lowpassfreq, t.lowpasswidth >= 0 ? (_.lowpass1 = 2 * (t.lowpassfreq - t.lowpasswidth), _.lowpass1 < 0 && (_.lowpass1 = 0)) : _.lowpass1 = (1 - 0) * 2 * t.lowpassfreq, _.lowpass1 /= t.out_samplerate, _.lowpass2 /= t.out_samplerate) : (_.lowpass1 = 0, _.lowpass2 = 0), Y(t), _.samplerate_index = s(t.out_samplerate, t), _.samplerate_index < 0)
        return t.internal_flags = null, -1;
      if (t.VBR == X.vbr_off) {
        if (t.free_format)
          _.bitrate_index = 0;
        else if (t.brate = r(
          t.brate,
          t.version,
          t.out_samplerate
        ), _.bitrate_index = n(
          t.brate,
          t.version,
          t.out_samplerate
        ), _.bitrate_index <= 0)
          return t.internal_flags = null, -1;
      } else
        _.bitrate_index = 1;
      t.analysis && (t.bWriteVbrTag = !1), _.pinfo != null && (t.bWriteVbrTag = !1), M.init_bit_stream_w(_);
      for (var I0 = _.samplerate_index + 3 * t.version + 6 * (t.out_samplerate < 16e3 ? 1 : 0), b0 = 0; b0 < U.SBMAX_l + 1; b0++)
        _.scalefac_band.l[b0] = H.sfBandIndex[I0].l[b0];
      for (var b0 = 0; b0 < U.PSFB21 + 1; b0++) {
        var G0 = (_.scalefac_band.l[22] - _.scalefac_band.l[21]) / U.PSFB21, e1 = _.scalefac_band.l[21] + b0 * G0;
        _.scalefac_band.psfb21[b0] = e1;
      }
      _.scalefac_band.psfb21[U.PSFB21] = 576;
      for (var b0 = 0; b0 < U.SBMAX_s + 1; b0++)
        _.scalefac_band.s[b0] = H.sfBandIndex[I0].s[b0];
      for (var b0 = 0; b0 < U.PSFB12 + 1; b0++) {
        var G0 = (_.scalefac_band.s[13] - _.scalefac_band.s[12]) / U.PSFB12, e1 = _.scalefac_band.s[12] + b0 * G0;
        _.scalefac_band.psfb12[b0] = e1;
      }
      _.scalefac_band.psfb12[U.PSFB12] = 192, t.version == 1 ? _.sideinfo_len = _.channels_out == 1 ? 4 + 17 : 4 + 32 : _.sideinfo_len = _.channels_out == 1 ? 4 + 9 : 4 + 17, t.error_protection && (_.sideinfo_len += 2), T(t), _.Class_ID = N;
      {
        var Y0;
        for (Y0 = 0; Y0 < 19; Y0++)
          _.nsPsy.pefirbuf[Y0] = 700 * _.mode_gr * _.channels_out;
        t.ATHtype == -1 && (t.ATHtype = 4);
      }
      switch (D(t.VBR_q <= 9), D(t.VBR_q >= 0), t.VBR) {
        case X.vbr_mt:
          t.VBR = X.vbr_mtrh;
        case X.vbr_mtrh: {
          t.useTemporal == null && (t.useTemporal = !1), p.apply_preset(t, 500 - t.VBR_q * 10, 0), t.quality < 0 && (t.quality = LAME_DEFAULT_QUALITY), t.quality < 5 && (t.quality = 0), t.quality > 5 && (t.quality = 5), _.PSY.mask_adjust = t.maskingadjust, _.PSY.mask_adjust_short = t.maskingadjust_short, t.experimentalY ? _.sfb21_extra = !1 : _.sfb21_extra = t.out_samplerate > 44e3, _.iteration_loop = new VBRNewIterationLoop(B);
          break;
        }
        case X.vbr_rh: {
          p.apply_preset(t, 500 - t.VBR_q * 10, 0), _.PSY.mask_adjust = t.maskingadjust, _.PSY.mask_adjust_short = t.maskingadjust_short, t.experimentalY ? _.sfb21_extra = !1 : _.sfb21_extra = t.out_samplerate > 44e3, t.quality > 6 && (t.quality = 6), t.quality < 0 && (t.quality = LAME_DEFAULT_QUALITY), _.iteration_loop = new VBROldIterationLoop(B);
          break;
        }
        default: {
          var v;
          _.sfb21_extra = !1, t.quality < 0 && (t.quality = LAME_DEFAULT_QUALITY), v = t.VBR, v == X.vbr_off && (t.VBR_mean_bitrate_kbps = t.brate), p.apply_preset(t, t.VBR_mean_bitrate_kbps, 0), t.VBR = v, _.PSY.mask_adjust = t.maskingadjust, _.PSY.mask_adjust_short = t.maskingadjust_short, v == X.vbr_off ? _.iteration_loop = new s0(B) : _.iteration_loop = new ABRIterationLoop(B);
          break;
        }
      }
      if (D(t.scale >= 0), t.VBR != X.vbr_off) {
        if (_.VBR_min_bitrate = 1, _.VBR_max_bitrate = 14, t.out_samplerate < 16e3 && (_.VBR_max_bitrate = 8), t.VBR_min_bitrate_kbps != 0 && (t.VBR_min_bitrate_kbps = r(
          t.VBR_min_bitrate_kbps,
          t.version,
          t.out_samplerate
        ), _.VBR_min_bitrate = n(
          t.VBR_min_bitrate_kbps,
          t.version,
          t.out_samplerate
        ), _.VBR_min_bitrate < 0) || t.VBR_max_bitrate_kbps != 0 && (t.VBR_max_bitrate_kbps = r(
          t.VBR_max_bitrate_kbps,
          t.version,
          t.out_samplerate
        ), _.VBR_max_bitrate = n(
          t.VBR_max_bitrate_kbps,
          t.version,
          t.out_samplerate
        ), _.VBR_max_bitrate < 0))
          return -1;
        t.VBR_min_bitrate_kbps = t0.bitrate_table[t.version][_.VBR_min_bitrate], t.VBR_max_bitrate_kbps = t0.bitrate_table[t.version][_.VBR_max_bitrate], t.VBR_mean_bitrate_kbps = Math.min(
          t0.bitrate_table[t.version][_.VBR_max_bitrate],
          t.VBR_mean_bitrate_kbps
        ), t.VBR_mean_bitrate_kbps = Math.max(
          t0.bitrate_table[t.version][_.VBR_min_bitrate],
          t.VBR_mean_bitrate_kbps
        );
      }
      return t.tune && (_.PSY.mask_adjust += t.tune_value_a, _.PSY.mask_adjust_short += t.tune_value_a), J(t), D(t.scale >= 0), t.athaa_type < 0 ? _.ATH.useAdjust = 3 : _.ATH.useAdjust = t.athaa_type, _.ATH.aaSensitivityP = Math.pow(10, t.athaa_sensitivity / -10), t.short_blocks == null && (t.short_blocks = z.short_block_allowed), t.short_blocks == z.short_block_allowed && (t.mode == o.JOINT_STEREO || t.mode == o.STEREO) && (t.short_blocks = z.short_block_coupled), t.quant_comp < 0 && (t.quant_comp = 1), t.quant_comp_short < 0 && (t.quant_comp_short = 0), t.msfix < 0 && (t.msfix = 0), t.exp_nspsytune = t.exp_nspsytune | 1, t.internal_flags.nsPsy.attackthre < 0 && (t.internal_flags.nsPsy.attackthre = g.NSATTACKTHRE), t.internal_flags.nsPsy.attackthre_s < 0 && (t.internal_flags.nsPsy.attackthre_s = g.NSATTACKTHRE_S), D(t.scale >= 0), t.scale < 0 && (t.scale = 1), t.ATHtype < 0 && (t.ATHtype = 4), t.ATHcurve < 0 && (t.ATHcurve = 4), t.athaa_loudapprox < 0 && (t.athaa_loudapprox = 2), t.interChRatio < 0 && (t.interChRatio = 0), t.useTemporal == null && (t.useTemporal = !0), _.slot_lag = _.frac_SpF = 0, t.VBR == X.vbr_off && (_.slot_lag = _.frac_SpF = (t.version + 1) * 72e3 * t.brate % t.out_samplerate | 0), H.iteration_init(t), I.psymodel_init(t), D(t.scale >= 0), 0;
    };
    function q(t, _) {
      (t.in_buffer_0 == null || t.in_buffer_nsamples < _) && (t.in_buffer_0 = u0(_), t.in_buffer_1 = u0(_), t.in_buffer_nsamples = _);
    }
    this.lame_encode_flush = function(t, _, S0, E0) {
      var V0 = t.internal_flags, H0 = Q([2, 1152]), y0 = 0, T0, F0, I0, b0, G0 = V0.mf_samples_to_encode - U.POSTDELAY, e1 = i0(t);
      if (V0.mf_samples_to_encode < 1)
        return 0;
      for (T0 = 0, t.in_samplerate != t.out_samplerate && (G0 += 16 * t.out_samplerate / t.in_samplerate), I0 = t.framesize - G0 % t.framesize, I0 < 576 && (I0 += t.framesize), t.encoder_padding = I0, b0 = (G0 + I0) / t.framesize; b0 > 0 && y0 >= 0; ) {
        var Y0 = e1 - V0.mf_size, v = t.frameNum;
        Y0 *= t.in_samplerate, Y0 /= t.out_samplerate, Y0 > 1152 && (Y0 = 1152), Y0 < 1 && (Y0 = 1), F0 = E0 - T0, E0 == 0 && (F0 = 0), y0 = this.lame_encode_buffer(
          t,
          H0[0],
          H0[1],
          Y0,
          _,
          S0,
          F0
        ), S0 += y0, T0 += y0, b0 -= v != t.frameNum ? 1 : 0;
      }
      if (V0.mf_samples_to_encode = 0, y0 < 0 || (F0 = E0 - T0, E0 == 0 && (F0 = 0), M.flush_bitstream(t), y0 = M.copy_buffer(
        V0,
        _,
        S0,
        F0,
        1
      ), y0 < 0))
        return y0;
      if (S0 += y0, T0 += y0, F0 = E0 - T0, E0 == 0 && (F0 = 0), t.write_id3tag_automatic) {
        if (b.id3tag_write_v1(t), y0 = M.copy_buffer(
          V0,
          _,
          S0,
          F0,
          0
        ), y0 < 0)
          return y0;
        T0 += y0;
      }
      return T0;
    }, this.lame_encode_buffer = function(t, _, S0, E0, V0, H0, y0) {
      var T0 = t.internal_flags, F0 = [null, null];
      if (T0.Class_ID != N)
        return -3;
      if (E0 == 0)
        return 0;
      q(T0, E0), F0[0] = T0.in_buffer_0, F0[1] = T0.in_buffer_1;
      for (var I0 = 0; I0 < E0; I0++)
        F0[0][I0] = _[I0], T0.channels_in > 1 && (F0[1][I0] = S0[I0]);
      return h0(
        t,
        F0[0],
        F0[1],
        E0,
        V0,
        H0,
        y0
      );
    };
    function i0(t) {
      var _ = U.BLKSIZE + t.framesize - U.FFTOFFSET;
      return _ = Math.max(_, 512 + t.framesize - 32), _;
    }
    function h0(t, _, S0, E0, V0, H0, y0) {
      var T0 = t.internal_flags, F0 = 0, I0, b0, G0, e1, Y0, v = [null, null], h = [null, null];
      if (T0.Class_ID != N)
        return -3;
      if (E0 == 0)
        return 0;
      if (Y0 = M.copy_buffer(T0, V0, H0, y0, 0), Y0 < 0)
        return Y0;
      if (H0 += Y0, F0 += Y0, h[0] = _, h[1] = S0, K.NEQ(t.scale, 0) && K.NEQ(t.scale, 1))
        for (b0 = 0; b0 < E0; ++b0)
          h[0][b0] *= t.scale, T0.channels_out == 2 && (h[1][b0] *= t.scale);
      if (K.NEQ(t.scale_left, 0) && K.NEQ(t.scale_left, 1))
        for (b0 = 0; b0 < E0; ++b0)
          h[0][b0] *= t.scale_left;
      if (K.NEQ(t.scale_right, 0) && K.NEQ(t.scale_right, 1))
        for (b0 = 0; b0 < E0; ++b0)
          h[1][b0] *= t.scale_right;
      if (t.num_channels == 2 && T0.channels_out == 1)
        for (b0 = 0; b0 < E0; ++b0)
          h[0][b0] = 0.5 * (h[0][b0] + h[1][b0]), h[1][b0] = 0;
      e1 = i0(t), v[0] = T0.mfbuf[0], v[1] = T0.mfbuf[1];
      for (var x = 0; E0 > 0; ) {
        var y = [null, null], k = 0, c = 0;
        y[0] = h[0], y[1] = h[1];
        var C = new M0();
        if (f1(
          t,
          v,
          y,
          x,
          E0,
          C
        ), k = C.n_in, c = C.n_out, T0.findReplayGain && !T0.decode_on_the_fly && l.AnalyzeSamples(
          T0.rgdata,
          v[0],
          T0.mf_size,
          v[1],
          T0.mf_size,
          c,
          T0.channels_out
        ) == GainAnalysis.GAIN_ANALYSIS_ERROR)
          return -6;
        if (E0 -= k, x += k, T0.channels_out == 2, T0.mf_size += c, D(T0.mf_size <= A.MFSIZE), T0.mf_samples_to_encode < 1 && (T0.mf_samples_to_encode = U.ENCDELAY + U.POSTDELAY), T0.mf_samples_to_encode += c, T0.mf_size >= e1) {
          var G = y0 - F0;
          if (y0 == 0 && (G = 0), I0 = d0(
            t,
            v[0],
            v[1],
            V0,
            H0,
            G
          ), I0 < 0)
            return I0;
          for (H0 += I0, F0 += I0, T0.mf_size -= t.framesize, T0.mf_samples_to_encode -= t.framesize, G0 = 0; G0 < T0.channels_out; G0++)
            for (b0 = 0; b0 < T0.mf_size; b0++)
              v[G0][b0] = v[G0][b0 + t.framesize];
        }
      }
      return F0;
    }
    function d0(t, _, S0, E0, V0, H0) {
      var y0 = u.enc.lame_encode_mp3_frame(
        t,
        _,
        S0,
        E0,
        V0,
        H0
      );
      return t.frameNum++, y0;
    }
    function M0() {
      this.n_in = 0, this.n_out = 0;
    }
    function R0() {
      this.num_used = 0;
    }
    function A0(t, _) {
      return _ != 0 ? A0(_, t % _) : t;
    }
    function w0(t, _, S0) {
      var E0 = Math.PI * _;
      t /= S0, t < 0 && (t = 0), t > 1 && (t = 1);
      var V0 = t - 0.5, H0 = 0.42 - 0.5 * Math.cos(2 * t * Math.PI) + 0.08 * Math.cos(4 * t * Math.PI);
      return Math.abs(V0) < 1e-9 ? E0 / Math.PI : H0 * Math.sin(S0 * E0 * V0) / (Math.PI * S0 * V0);
    }
    function $0(t, _, S0, E0, V0, H0, y0, T0, F0) {
      var I0 = t.internal_flags, b0, G0 = 0, e1, Y0 = t.out_samplerate / A0(t.out_samplerate, t.in_samplerate);
      Y0 > A.BPC && (Y0 = A.BPC);
      var v = Math.abs(I0.resample_ratio - Math.floor(0.5 + I0.resample_ratio)) < 1e-4 ? 1 : 0, h = 1 / I0.resample_ratio;
      h > 1 && (h = 1);
      var x = 31;
      x % 2 == 0 && --x, x += v;
      var y = x + 1;
      if (I0.fill_buffer_resample_init == 0) {
        for (I0.inbuf_old[0] = u0(y), I0.inbuf_old[1] = u0(y), b0 = 0; b0 <= 2 * Y0; ++b0)
          I0.blackfilt[b0] = u0(y);
        for (I0.itime[0] = 0, I0.itime[1] = 0, G0 = 0; G0 <= 2 * Y0; G0++) {
          var k = 0, c = (G0 - Y0) / (2 * Y0);
          for (b0 = 0; b0 <= x; b0++)
            k += I0.blackfilt[G0][b0] = w0(
              b0 - c,
              h,
              x
            );
          for (b0 = 0; b0 <= x; b0++)
            I0.blackfilt[G0][b0] /= k;
        }
        I0.fill_buffer_resample_init = 1;
      }
      var C = I0.inbuf_old[F0];
      for (e1 = 0; e1 < E0; e1++) {
        var G, F;
        if (G = e1 * I0.resample_ratio, G0 = 0 | Math.floor(G - I0.itime[F0]), x + G0 - x / 2 >= y0)
          break;
        var c = G - I0.itime[F0] - (G0 + 0.5 * (x % 2));
        F = 0 | Math.floor(c * 2 * Y0 + Y0 + 0.5);
        var e0 = 0;
        for (b0 = 0; b0 <= x; ++b0) {
          var $ = 0 | b0 + G0 - x / 2, a0;
          a0 = $ < 0 ? C[y + $] : V0[H0 + $], e0 += a0 * I0.blackfilt[F][b0];
        }
        _[S0 + e1] = e0;
      }
      if (T0.num_used = Math.min(y0, x + G0 - x / 2), I0.itime[F0] += T0.num_used - e1 * I0.resample_ratio, T0.num_used >= y)
        for (b0 = 0; b0 < y; b0++)
          C[b0] = V0[H0 + T0.num_used + b0 - y];
      else {
        var m0 = y - T0.num_used;
        for (b0 = 0; b0 < m0; ++b0)
          C[b0] = C[b0 + T0.num_used];
        for (G0 = 0; b0 < y; ++b0, ++G0)
          C[b0] = V0[H0 + G0];
        D(G0 == T0.num_used);
      }
      return e1;
    }
    function f1(t, _, S0, E0, V0, H0) {
      var y0 = t.internal_flags;
      if (y0.resample_ratio < 0.9999 || y0.resample_ratio > 1.0001)
        for (var T0 = 0; T0 < y0.channels_out; T0++) {
          var F0 = new R0();
          H0.n_out = $0(
            t,
            _[T0],
            y0.mf_size,
            t.framesize,
            S0[T0],
            E0,
            V0,
            F0,
            T0
          ), H0.n_in = F0.num_used;
        }
      else {
        H0.n_out = Math.min(t.framesize, V0), H0.n_in = H0.n_out;
        for (var I0 = 0; I0 < H0.n_out; ++I0)
          _[0][y0.mf_size + I0] = S0[0][E0 + I0], y0.channels_out == 2 && (_[1][y0.mf_size + I0] = S0[1][E0 + I0]);
      }
    }
  }
  return Te = R, Te;
}
var p2 = Q0, M1 = p2.VbrMode;
function H2() {
  var w = Oe();
  function Z(A, m, O, s0, K, t0, U, R, o, u, d, e, l, M, p) {
    this.vbr_q = A, this.quant_comp = m, this.quant_comp_s = O, this.expY = s0, this.st_lrm = K, this.st_s = t0, this.masking_adj = U, this.masking_adj_short = R, this.ath_lower = o, this.ath_curve = u, this.ath_sensitivity = d, this.interch = e, this.safejoint = l, this.sfb21mod = M, this.msfix = p;
  }
  function X(A, m, O, s0, K, t0, U, R, o, u, d, e, l, M) {
    this.quant_comp = m, this.quant_comp_s = O, this.safejoint = s0, this.nsmsfix = K, this.st_lrm = t0, this.st_s = U, this.nsbass = R, this.scale = o, this.masking_adj = u, this.ath_lower = d, this.ath_curve = e, this.interch = l, this.sfscale = M;
  }
  var z;
  this.setModules = function(A) {
    z = A;
  };
  var u0 = [
    new Z(0, 9, 9, 0, 5.2, 125, -4.2, -6.3, 4.8, 1, 0, 0, 2, 21, 0.97),
    new Z(1, 9, 9, 0, 5.3, 125, -3.6, -5.6, 4.5, 1.5, 0, 0, 2, 21, 1.35),
    new Z(2, 9, 9, 0, 5.6, 125, -2.2, -3.5, 2.8, 2, 0, 0, 2, 21, 1.49),
    new Z(3, 9, 9, 1, 5.8, 130, -1.8, -2.8, 2.6, 3, -4, 0, 2, 20, 1.64),
    new Z(4, 9, 9, 1, 6, 135, -0.7, -1.1, 1.1, 3.5, -8, 0, 2, 0, 1.79),
    new Z(5, 9, 9, 1, 6.4, 140, 0.5, 0.4, -7.5, 4, -12, 2e-4, 0, 0, 1.95),
    new Z(6, 9, 9, 1, 6.6, 145, 0.67, 0.65, -14.7, 6.5, -19, 4e-4, 0, 0, 2.3),
    new Z(7, 9, 9, 1, 6.6, 145, 0.8, 0.75, -19.7, 8, -22, 6e-4, 0, 0, 2.7),
    new Z(8, 9, 9, 1, 6.6, 145, 1.2, 1.15, -27.5, 10, -23, 7e-4, 0, 0, 0),
    new Z(9, 9, 9, 1, 6.6, 145, 1.6, 1.6, -36, 11, -25, 8e-4, 0, 0, 0),
    new Z(10, 9, 9, 1, 6.6, 145, 2, 2, -36, 12, -25, 8e-4, 0, 0, 0)
  ], W = [
    new Z(0, 9, 9, 0, 4.2, 25, -7, -4, 7.5, 1, 0, 0, 2, 26, 0.97),
    new Z(1, 9, 9, 0, 4.2, 25, -5.6, -3.6, 4.5, 1.5, 0, 0, 2, 21, 1.35),
    new Z(2, 9, 9, 0, 4.2, 25, -4.4, -1.8, 2, 2, 0, 0, 2, 18, 1.49),
    new Z(3, 9, 9, 1, 4.2, 25, -3.4, -1.25, 1.1, 3, -4, 0, 2, 15, 1.64),
    new Z(4, 9, 9, 1, 4.2, 25, -2.2, 0.1, 0, 3.5, -8, 0, 2, 0, 1.79),
    new Z(5, 9, 9, 1, 4.2, 25, -1, 1.65, -7.7, 4, -12, 2e-4, 0, 0, 1.95),
    new Z(6, 9, 9, 1, 4.2, 25, -0, 2.47, -7.7, 6.5, -19, 4e-4, 0, 0, 2),
    new Z(7, 9, 9, 1, 4.2, 25, 0.5, 2, -14.5, 8, -22, 6e-4, 0, 0, 2),
    new Z(8, 9, 9, 1, 4.2, 25, 1, 2.4, -22, 10, -23, 7e-4, 0, 0, 2),
    new Z(9, 9, 9, 1, 4.2, 25, 1.5, 2.95, -30, 11, -25, 8e-4, 0, 0, 2),
    new Z(10, 9, 9, 1, 4.2, 25, 2, 2.95, -36, 12, -30, 8e-4, 0, 0, 2)
  ];
  function Q(A, m, O) {
    var s0 = A.VBR == M1.vbr_rh ? u0 : W, K = A.VBR_q_frac, t0 = s0[m], U = s0[m + 1], R = t0;
    t0.st_lrm = t0.st_lrm + K * (U.st_lrm - t0.st_lrm), t0.st_s = t0.st_s + K * (U.st_s - t0.st_s), t0.masking_adj = t0.masking_adj + K * (U.masking_adj - t0.masking_adj), t0.masking_adj_short = t0.masking_adj_short + K * (U.masking_adj_short - t0.masking_adj_short), t0.ath_lower = t0.ath_lower + K * (U.ath_lower - t0.ath_lower), t0.ath_curve = t0.ath_curve + K * (U.ath_curve - t0.ath_curve), t0.ath_sensitivity = t0.ath_sensitivity + K * (U.ath_sensitivity - t0.ath_sensitivity), t0.interch = t0.interch + K * (U.interch - t0.interch), t0.msfix = t0.msfix + K * (U.msfix - t0.msfix), f0(A, R.vbr_q), O != 0 ? A.quant_comp = R.quant_comp : Math.abs(A.quant_comp - -1) > 0 || (A.quant_comp = R.quant_comp), O != 0 ? A.quant_comp_short = R.quant_comp_s : Math.abs(A.quant_comp_short - -1) > 0 || (A.quant_comp_short = R.quant_comp_s), R.expY != 0 && (A.experimentalY = R.expY != 0), O != 0 ? A.internal_flags.nsPsy.attackthre = R.st_lrm : Math.abs(A.internal_flags.nsPsy.attackthre - -1) > 0 || (A.internal_flags.nsPsy.attackthre = R.st_lrm), O != 0 ? A.internal_flags.nsPsy.attackthre_s = R.st_s : Math.abs(A.internal_flags.nsPsy.attackthre_s - -1) > 0 || (A.internal_flags.nsPsy.attackthre_s = R.st_s), O != 0 ? A.maskingadjust = R.masking_adj : Math.abs(A.maskingadjust - 0) > 0 || (A.maskingadjust = R.masking_adj), O != 0 ? A.maskingadjust_short = R.masking_adj_short : Math.abs(A.maskingadjust_short - 0) > 0 || (A.maskingadjust_short = R.masking_adj_short), O != 0 ? A.ATHlower = -R.ath_lower / 10 : Math.abs(-A.ATHlower * 10 - 0) > 0 || (A.ATHlower = -R.ath_lower / 10), O != 0 ? A.ATHcurve = R.ath_curve : Math.abs(A.ATHcurve - -1) > 0 || (A.ATHcurve = R.ath_curve), O != 0 ? A.athaa_sensitivity = R.ath_sensitivity : Math.abs(A.athaa_sensitivity - -1) > 0 || (A.athaa_sensitivity = R.ath_sensitivity), R.interch > 0 && (O != 0 ? A.interChRatio = R.interch : Math.abs(A.interChRatio - -1) > 0 || (A.interChRatio = R.interch)), R.safejoint > 0 && (A.exp_nspsytune = A.exp_nspsytune | R.safejoint), R.sfb21mod > 0 && (A.exp_nspsytune = A.exp_nspsytune | R.sfb21mod << 20), O != 0 ? A.msfix = R.msfix : Math.abs(A.msfix - -1) > 0 || (A.msfix = R.msfix), O == 0 && (A.VBR_q = m, A.VBR_q_frac = K);
  }
  var D = [
    new X(8, 9, 9, 0, 0, 6.6, 145, 0, 0.95, 0, -30, 11, 12e-4, 1),
    /*   8, impossible to use in stereo */
    new X(16, 9, 9, 0, 0, 6.6, 145, 0, 0.95, 0, -25, 11, 1e-3, 1),
    /*  16 */
    new X(24, 9, 9, 0, 0, 6.6, 145, 0, 0.95, 0, -20, 11, 1e-3, 1),
    /*  24 */
    new X(32, 9, 9, 0, 0, 6.6, 145, 0, 0.95, 0, -15, 11, 1e-3, 1),
    /*  32 */
    new X(40, 9, 9, 0, 0, 6.6, 145, 0, 0.95, 0, -10, 11, 9e-4, 1),
    /*  40 */
    new X(48, 9, 9, 0, 0, 6.6, 145, 0, 0.95, 0, -10, 11, 9e-4, 1),
    /*  48 */
    new X(56, 9, 9, 0, 0, 6.6, 145, 0, 0.95, 0, -6, 11, 8e-4, 1),
    /*  56 */
    new X(64, 9, 9, 0, 0, 6.6, 145, 0, 0.95, 0, -2, 11, 8e-4, 1),
    /*  64 */
    new X(80, 9, 9, 0, 0, 6.6, 145, 0, 0.95, 0, 0, 8, 7e-4, 1),
    /*  80 */
    new X(96, 9, 9, 0, 2.5, 6.6, 145, 0, 0.95, 0, 1, 5.5, 6e-4, 1),
    /*  96 */
    new X(112, 9, 9, 0, 2.25, 6.6, 145, 0, 0.95, 0, 2, 4.5, 5e-4, 1),
    /* 112 */
    new X(128, 9, 9, 0, 1.95, 6.4, 140, 0, 0.95, 0, 3, 4, 2e-4, 1),
    /* 128 */
    new X(160, 9, 9, 1, 1.79, 6, 135, 0, 0.95, -2, 5, 3.5, 0, 1),
    /* 160 */
    new X(192, 9, 9, 1, 1.49, 5.6, 125, 0, 0.97, -4, 7, 3, 0, 0),
    /* 192 */
    new X(224, 9, 9, 1, 1.25, 5.2, 125, 0, 0.98, -6, 9, 2, 0, 0),
    /* 224 */
    new X(256, 9, 9, 1, 0.97, 5.2, 125, 0, 1, -8, 10, 1, 0, 0),
    /* 256 */
    new X(320, 9, 9, 1, 0.9, 5.2, 125, 0, 1, -10, 12, 0, 0, 0)
    /* 320 */
  ];
  function g(A, m, O) {
    var s0 = m, K = z.nearestBitrateFullIndex(m);
    if (A.VBR = M1.vbr_abr, A.VBR_mean_bitrate_kbps = s0, A.VBR_mean_bitrate_kbps = Math.min(A.VBR_mean_bitrate_kbps, 320), A.VBR_mean_bitrate_kbps = Math.max(A.VBR_mean_bitrate_kbps, 8), A.brate = A.VBR_mean_bitrate_kbps, A.VBR_mean_bitrate_kbps > 320 && (A.disable_reservoir = !0), D[K].safejoint > 0 && (A.exp_nspsytune = A.exp_nspsytune | 2), D[K].sfscale > 0 && (A.internal_flags.noise_shaping = 2), Math.abs(D[K].nsbass) > 0) {
      var t0 = int(D[K].nsbass * 4);
      t0 < 0 && (t0 += 64), A.exp_nspsytune = A.exp_nspsytune | t0 << 2;
    }
    return O != 0 ? A.quant_comp = D[K].quant_comp : Math.abs(A.quant_comp - -1) > 0 || (A.quant_comp = D[K].quant_comp), O != 0 ? A.quant_comp_short = D[K].quant_comp_s : Math.abs(A.quant_comp_short - -1) > 0 || (A.quant_comp_short = D[K].quant_comp_s), O != 0 ? A.msfix = D[K].nsmsfix : Math.abs(A.msfix - -1) > 0 || (A.msfix = D[K].nsmsfix), O != 0 ? A.internal_flags.nsPsy.attackthre = D[K].st_lrm : Math.abs(A.internal_flags.nsPsy.attackthre - -1) > 0 || (A.internal_flags.nsPsy.attackthre = D[K].st_lrm), O != 0 ? A.internal_flags.nsPsy.attackthre_s = D[K].st_s : Math.abs(A.internal_flags.nsPsy.attackthre_s - -1) > 0 || (A.internal_flags.nsPsy.attackthre_s = D[K].st_s), O != 0 ? A.scale = D[K].scale : Math.abs(A.scale - -1) > 0 || (A.scale = D[K].scale), O != 0 ? A.maskingadjust = D[K].masking_adj : Math.abs(A.maskingadjust - 0) > 0 || (A.maskingadjust = D[K].masking_adj), D[K].masking_adj > 0 ? O != 0 ? A.maskingadjust_short = D[K].masking_adj * 0.9 : Math.abs(A.maskingadjust_short - 0) > 0 || (A.maskingadjust_short = D[K].masking_adj * 0.9) : O != 0 ? A.maskingadjust_short = D[K].masking_adj * 1.1 : Math.abs(A.maskingadjust_short - 0) > 0 || (A.maskingadjust_short = D[K].masking_adj * 1.1), O != 0 ? A.ATHlower = -D[K].ath_lower / 10 : Math.abs(-A.ATHlower * 10 - 0) > 0 || (A.ATHlower = -D[K].ath_lower / 10), O != 0 ? A.ATHcurve = D[K].ath_curve : Math.abs(A.ATHcurve - -1) > 0 || (A.ATHcurve = D[K].ath_curve), O != 0 ? A.interChRatio = D[K].interch : Math.abs(A.interChRatio - -1) > 0 || (A.interChRatio = D[K].interch), m;
  }
  this.apply_preset = function(A, m, O) {
    switch (m) {
      case w.R3MIX: {
        m = w.V3, A.VBR = M1.vbr_mtrh;
        break;
      }
      case w.MEDIUM: {
        m = w.V4, A.VBR = M1.vbr_rh;
        break;
      }
      case w.MEDIUM_FAST: {
        m = w.V4, A.VBR = M1.vbr_mtrh;
        break;
      }
      case w.STANDARD: {
        m = w.V2, A.VBR = M1.vbr_rh;
        break;
      }
      case w.STANDARD_FAST: {
        m = w.V2, A.VBR = M1.vbr_mtrh;
        break;
      }
      case w.EXTREME: {
        m = w.V0, A.VBR = M1.vbr_rh;
        break;
      }
      case w.EXTREME_FAST: {
        m = w.V0, A.VBR = M1.vbr_mtrh;
        break;
      }
      case w.INSANE:
        return m = 320, A.preset = m, g(A, m, O), A.VBR = M1.vbr_off, m;
    }
    switch (A.preset = m, m) {
      case w.V9:
        return Q(A, 9, O), m;
      case w.V8:
        return Q(A, 8, O), m;
      case w.V7:
        return Q(A, 7, O), m;
      case w.V6:
        return Q(A, 6, O), m;
      case w.V5:
        return Q(A, 5, O), m;
      case w.V4:
        return Q(A, 4, O), m;
      case w.V3:
        return Q(A, 3, O), m;
      case w.V2:
        return Q(A, 2, O), m;
      case w.V1:
        return Q(A, 1, O), m;
      case w.V0:
        return Q(A, 0, O), m;
    }
    return 8 <= m && m <= 320 ? g(A, m, O) : (A.preset = 0, m);
  };
  function f0(A, m) {
    var O = 0;
    return 0 > m && (O = -1, m = 0), 9 < m && (O = -1, m = 9), A.VBR_q = m, A.VBR_q_frac = 0, O;
  }
}
var V2 = H2;
function O2() {
  this.setModules = function(w, Z) {
  };
}
var C2 = O2;
function F2() {
  this.over_noise = 0, this.tot_noise = 0, this.max_noise = 0, this.over_count = 0, this.over_SSD = 0, this.bits = 0;
}
var k2 = F2, Ca = Q0, na = Ca.new_float, X2 = Ca.new_int;
function Y2() {
  this.global_gain = 0, this.sfb_count1 = 0, this.step = X2(39), this.noise = na(39), this.noise_log = na(39);
}
var q2 = Y2, q1 = Q0, y1 = q1.System, _a = q1.VbrMode, ye = q1.Util, X1 = q1.Arrays, K1 = q1.new_float, U1 = q1.assert, D2 = C2, we = k2, G2 = q2, D0 = t1(), la = Le, va = ie;
function $2() {
  var w;
  this.rv = null;
  var Z;
  this.qupvt = null;
  var X, z = new D2(), u0;
  this.setModules = function(R, o, u, d) {
    w = R, Z = o, this.rv = o, X = u, this.qupvt = u, u0 = d, z.setModules(X, u0);
  }, this.ms_convert = function(R, o) {
    for (var u = 0; u < 576; ++u) {
      var d = R.tt[o][0].xr[u], e = R.tt[o][1].xr[u];
      R.tt[o][0].xr[u] = (d + e) * (ye.SQRT2 * 0.5), R.tt[o][1].xr[u] = (d - e) * (ye.SQRT2 * 0.5);
    }
  };
  function W(R, o, u, d) {
    d = 0;
    for (var e = 0; e <= u; ++e) {
      var l = Math.abs(R.xr[e]);
      d += l, o[e] = Math.sqrt(l * Math.sqrt(l)), o[e] > R.xrpow_max && (R.xrpow_max = o[e]);
    }
    return d;
  }
  this.init_xrpow = function(R, o, u) {
    var d = 0, e = 0 | o.max_nonzero_coeff;
    if (o.xrpow_max = 0, X1.fill(u, e, 576, 0), d = W(o, u, e, d), d > 1e-20) {
      var l = 0;
      R.substep_shaping & 2 && (l = 1);
      for (var M = 0; M < o.psymax; M++)
        R.pseudohalf[M] = l;
      return !0;
    }
    return X1.fill(o.l3_enc, 0, 576, 0), !1;
  };
  function Q(R, o) {
    var u = R.ATH, d = o.xr;
    if (o.block_type != D0.SHORT_TYPE)
      for (var e = !1, l = D0.PSFB21 - 1; l >= 0 && !e; l--) {
        var M = R.scalefac_band.psfb21[l], p = R.scalefac_band.psfb21[l + 1], H = X.athAdjust(
          u.adjust,
          u.psfb21[l],
          u.floor
        );
        R.nsPsy.longfact[21] > 1e-12 && (H *= R.nsPsy.longfact[21]);
        for (var B = p - 1; B >= M; B--)
          if (Math.abs(d[B]) < H)
            d[B] = 0;
          else {
            e = !0;
            break;
          }
      }
    else
      for (var I = 0; I < 3; I++)
        for (var e = !1, l = D0.PSFB12 - 1; l >= 0 && !e; l--) {
          var M = R.scalefac_band.s[12] * 3 + (R.scalefac_band.s[13] - R.scalefac_band.s[12]) * I + (R.scalefac_band.psfb12[l] - R.scalefac_band.psfb12[0]), p = M + (R.scalefac_band.psfb12[l + 1] - R.scalefac_band.psfb12[l]), v0 = X.athAdjust(
            u.adjust,
            u.psfb12[l],
            u.floor
          );
          R.nsPsy.shortfact[12] > 1e-12 && (v0 *= R.nsPsy.shortfact[12]);
          for (var B = p - 1; B >= M; B--)
            if (Math.abs(d[B]) < v0)
              d[B] = 0;
            else {
              e = !0;
              break;
            }
        }
  }
  this.init_outer_loop = function(R, o) {
    o.part2_3_length = 0, o.big_values = 0, o.count1 = 0, o.global_gain = 210, o.scalefac_compress = 0, o.table_select[0] = 0, o.table_select[1] = 0, o.table_select[2] = 0, o.subblock_gain[0] = 0, o.subblock_gain[1] = 0, o.subblock_gain[2] = 0, o.subblock_gain[3] = 0, o.region0_count = 0, o.region1_count = 0, o.preflag = 0, o.scalefac_scale = 0, o.count1table_select = 0, o.part2_length = 0, o.sfb_lmax = D0.SBPSY_l, o.sfb_smin = D0.SBPSY_s, o.psy_lmax = R.sfb21_extra ? D0.SBMAX_l : D0.SBPSY_l, o.psymax = o.psy_lmax, o.sfbmax = o.sfb_lmax, o.sfbdivide = 11;
    for (var u = 0; u < D0.SBMAX_l; u++)
      o.width[u] = R.scalefac_band.l[u + 1] - R.scalefac_band.l[u], o.window[u] = 3;
    if (o.block_type == D0.SHORT_TYPE) {
      var d = K1(576);
      o.sfb_smin = 0, o.sfb_lmax = 0, o.mixed_block_flag != 0 && (o.sfb_smin = 3, o.sfb_lmax = R.mode_gr * 2 + 4), o.psymax = o.sfb_lmax + 3 * ((R.sfb21_extra ? D0.SBMAX_s : D0.SBPSY_s) - o.sfb_smin), o.sfbmax = o.sfb_lmax + 3 * (D0.SBPSY_s - o.sfb_smin), o.sfbdivide = o.sfbmax - 18, o.psy_lmax = o.sfb_lmax;
      var e = R.scalefac_band.l[o.sfb_lmax];
      y1.arraycopy(o.xr, 0, d, 0, 576);
      for (var u = o.sfb_smin; u < D0.SBMAX_s; u++)
        for (var l = R.scalefac_band.s[u], M = R.scalefac_band.s[u + 1], p = 0; p < 3; p++)
          for (var H = l; H < M; H++)
            o.xr[e++] = d[3 * H + p];
      for (var B = o.sfb_lmax, u = o.sfb_smin; u < D0.SBMAX_s; u++)
        o.width[B] = o.width[B + 1] = o.width[B + 2] = R.scalefac_band.s[u + 1] - R.scalefac_band.s[u], o.window[B] = 0, o.window[B + 1] = 1, o.window[B + 2] = 2, B += 3;
    }
    o.count1bits = 0, o.sfb_partition_table = X.nr_of_sfb_block[0][0], o.slen[0] = 0, o.slen[1] = 0, o.slen[2] = 0, o.slen[3] = 0, o.max_nonzero_coeff = 575, X1.fill(o.scalefac, 0), Q(R, o);
  };
  function D(R) {
    this.ordinal = R;
  }
  D.BINSEARCH_NONE = new D(0), D.BINSEARCH_UP = new D(1), D.BINSEARCH_DOWN = new D(2);
  function g(R, o, u, d, e) {
    var l, M = R.CurrentStep[d], p = !1, H = R.OldValue[d], B = D.BINSEARCH_NONE;
    for (o.global_gain = H, u -= o.part2_length; ; ) {
      var I;
      if (l = u0.count_bits(R, e, o, null), M == 1 || l == u)
        break;
      l > u ? (B == D.BINSEARCH_DOWN && (p = !0), p && (M /= 2), B = D.BINSEARCH_UP, I = M) : (B == D.BINSEARCH_UP && (p = !0), p && (M /= 2), B = D.BINSEARCH_DOWN, I = -M), o.global_gain += I, o.global_gain < 0 && (o.global_gain = 0, p = !0), o.global_gain > 255 && (o.global_gain = 255, p = !0);
    }
    for (U1(o.global_gain >= 0), U1(o.global_gain < 256); l > u && o.global_gain < 255; )
      o.global_gain++, l = u0.count_bits(R, e, o, null);
    return R.CurrentStep[d] = H - o.global_gain >= 4 ? 4 : 2, R.OldValue[d] = o.global_gain, o.part2_3_length = l, l;
  }
  this.trancate_smallspectrums = function(R, o, u, d) {
    var e = K1(va.SFBMAX);
    if (!(!(R.substep_shaping & 4) && o.block_type == D0.SHORT_TYPE || R.substep_shaping & 128)) {
      X.calc_noise(o, u, e, new we(), null);
      for (var M = 0; M < 576; M++) {
        var l = 0;
        o.l3_enc[M] != 0 && (l = Math.abs(o.xr[M])), d[M] = l;
      }
      var M = 0, p = 8;
      o.block_type == D0.SHORT_TYPE && (p = 6);
      do {
        var H, B, I, v0, b = o.width[p];
        if (M += b, !(e[p] >= 1) && (X1.sort(d, M - b, b), !BitStream.EQ(d[M - 1], 0))) {
          H = (1 - e[p]) * u[p], B = 0, v0 = 0;
          do {
            var a;
            for (I = 1; v0 + I < b && !BitStream.NEQ(d[v0 + M - b], d[v0 + M + I - b]); I++)
              ;
            if (a = d[v0 + M - b] * d[v0 + M - b] * I, H < a) {
              v0 != 0 && (B = d[v0 + M - b - 1]);
              break;
            }
            H -= a, v0 += I;
          } while (v0 < b);
          if (!BitStream.EQ(B, 0))
            do
              Math.abs(o.xr[M - b]) <= B && (o.l3_enc[M - b] = 0);
            while (--b > 0);
        }
      } while (++p < o.psymax);
      o.part2_3_length = u0.noquant_count_bits(R, o, null);
    }
  };
  function f0(R) {
    for (var o = 0; o < R.sfbmax; o++)
      if (R.scalefac[o] + R.subblock_gain[R.window[o]] == 0)
        return !1;
    return !0;
  }
  function A(R) {
    return ye.FAST_LOG10(0.368 + 0.632 * R * R * R);
  }
  function m(R, o) {
    for (var u = 1e-37, d = 0; d < o.psymax; d++)
      u += A(R[d]);
    return Math.max(1e-20, u);
  }
  function O(R, o, u, d, e) {
    var l;
    switch (R) {
      default:
      case 9: {
        o.over_count > 0 ? (l = u.over_SSD <= o.over_SSD, u.over_SSD == o.over_SSD && (l = u.bits < o.bits)) : l = u.max_noise < 0 && u.max_noise * 10 + u.bits <= o.max_noise * 10 + o.bits;
        break;
      }
      case 0:
        l = u.over_count < o.over_count || u.over_count == o.over_count && u.over_noise < o.over_noise || u.over_count == o.over_count && BitStream.EQ(u.over_noise, o.over_noise) && u.tot_noise < o.tot_noise;
        break;
      case 8:
        u.max_noise = m(e, d);
      case 1:
        l = u.max_noise < o.max_noise;
        break;
      case 2:
        l = u.tot_noise < o.tot_noise;
        break;
      case 3:
        l = u.tot_noise < o.tot_noise && u.max_noise < o.max_noise;
        break;
      case 4:
        l = u.max_noise <= 0 && o.max_noise > 0.2 || u.max_noise <= 0 && o.max_noise < 0 && o.max_noise > u.max_noise - 0.2 && u.tot_noise < o.tot_noise || u.max_noise <= 0 && o.max_noise > 0 && o.max_noise > u.max_noise - 0.2 && u.tot_noise < o.tot_noise + o.over_noise || u.max_noise > 0 && o.max_noise > -0.05 && o.max_noise > u.max_noise - 0.1 && u.tot_noise + u.over_noise < o.tot_noise + o.over_noise || u.max_noise > 0 && o.max_noise > -0.1 && o.max_noise > u.max_noise - 0.15 && u.tot_noise + u.over_noise + u.over_noise < o.tot_noise + o.over_noise + o.over_noise;
        break;
      case 5:
        l = u.over_noise < o.over_noise || BitStream.EQ(u.over_noise, o.over_noise) && u.tot_noise < o.tot_noise;
        break;
      case 6:
        l = u.over_noise < o.over_noise || BitStream.EQ(u.over_noise, o.over_noise) && (u.max_noise < o.max_noise || BitStream.EQ(u.max_noise, o.max_noise) && u.tot_noise <= o.tot_noise);
        break;
      case 7:
        l = u.over_count < o.over_count || u.over_noise < o.over_noise;
        break;
    }
    return o.over_count == 0 && (l = l && u.bits < o.bits), l;
  }
  function s0(R, o, u, d, e) {
    var l = R.internal_flags, M;
    o.scalefac_scale == 0 ? M = 1.2968395546510096 : M = 1.6817928305074292;
    for (var p = 0, H = 0; H < o.sfbmax; H++)
      p < u[H] && (p = u[H]);
    var B = l.noise_shaping_amp;
    switch (B == 3 && (e ? B = 2 : B = 1), B) {
      case 2:
        break;
      case 1:
        p > 1 ? p = Math.pow(p, 0.5) : p *= 0.95;
        break;
      case 0:
      default:
        p > 1 ? p = 1 : p *= 0.95;
        break;
    }
    for (var I = 0, H = 0; H < o.sfbmax; H++) {
      var v0 = o.width[H], b;
      if (I += v0, !(u[H] < p)) {
        if (l.substep_shaping & 2 && (l.pseudohalf[H] = l.pseudohalf[H] == 0 ? 1 : 0, l.pseudohalf[H] == 0 && l.noise_shaping_amp == 2))
          return;
        for (o.scalefac[H]++, b = -v0; b < 0; b++)
          d[I + b] *= M, d[I + b] > o.xrpow_max && (o.xrpow_max = d[I + b]);
        if (l.noise_shaping_amp == 2)
          return;
      }
    }
  }
  function K(R, o) {
    for (var u = 1.2968395546510096, d = 0, e = 0; e < R.sfbmax; e++) {
      var l = R.width[e], M = R.scalefac[e];
      if (R.preflag != 0 && (M += X.pretab[e]), d += l, M & 1) {
        M++;
        for (var p = -l; p < 0; p++)
          o[d + p] *= u, o[d + p] > R.xrpow_max && (R.xrpow_max = o[d + p]);
      }
      R.scalefac[e] = M >> 1;
    }
    R.preflag = 0, R.scalefac_scale = 1;
  }
  function t0(R, o, u) {
    var d, e = o.scalefac;
    for (d = 0; d < o.sfb_lmax; d++)
      if (e[d] >= 16)
        return !0;
    for (var l = 0; l < 3; l++) {
      var M = 0, p = 0;
      for (d = o.sfb_lmax + l; d < o.sfbdivide; d += 3)
        M < e[d] && (M = e[d]);
      for (; d < o.sfbmax; d += 3)
        p < e[d] && (p = e[d]);
      if (!(M < 16 && p < 8)) {
        if (o.subblock_gain[l] >= 7)
          return !0;
        o.subblock_gain[l]++;
        var H = R.scalefac_band.l[o.sfb_lmax];
        for (d = o.sfb_lmax + l; d < o.sfbmax; d += 3) {
          var B, I = o.width[d], v0 = e[d];
          if (v0 = v0 - (4 >> o.scalefac_scale), v0 >= 0) {
            e[d] = v0, H += I * 3;
            continue;
          }
          e[d] = 0;
          {
            var b = 210 + (v0 << o.scalefac_scale + 1);
            B = X.IPOW20(b);
          }
          H += I * (l + 1);
          for (var a = -I; a < 0; a++)
            u[H + a] *= B, u[H + a] > o.xrpow_max && (o.xrpow_max = u[H + a]);
          H += I * (3 - l - 1);
        }
        {
          var B = X.IPOW20(202);
          H += o.width[d] * (l + 1);
          for (var a = -o.width[d]; a < 0; a++)
            u[H + a] *= B, u[H + a] > o.xrpow_max && (o.xrpow_max = u[H + a]);
        }
      }
    }
    return !1;
  }
  function U(R, o, u, d, e) {
    var l = R.internal_flags;
    s0(R, o, u, d, e);
    var M = f0(o);
    return M ? !1 : (l.mode_gr == 2 ? M = u0.scale_bitcount(o) : M = u0.scale_bitcount_lsf(l, o), M ? (l.noise_shaping > 1 && (X1.fill(l.pseudohalf, 0), o.scalefac_scale == 0 ? (K(o, d), M = !1) : o.block_type == D0.SHORT_TYPE && l.subblock_gain > 0 && (M = t0(l, o, d) || f0(o))), M || (l.mode_gr == 2 ? M = u0.scale_bitcount(o) : M = u0.scale_bitcount_lsf(l, o)), !M) : !0);
  }
  this.outer_loop = function(R, o, u, d, e, l) {
    var M = R.internal_flags, p = new la(), H = K1(576), B = K1(va.SFBMAX), I = new we(), v0, b = new G2(), a = 9999999, S = !1, L = !1, V = 0;
    if (g(M, o, l, e, d), M.noise_shaping == 0)
      return 100;
    X.calc_noise(
      o,
      u,
      B,
      I,
      b
    ), I.bits = o.part2_3_length, p.assign(o);
    var N = 0;
    for (y1.arraycopy(d, 0, H, 0, 576); !S; ) {
      do {
        var P = new we(), E, i = 255;
        if (M.substep_shaping & 2 ? E = 20 : E = 3, M.sfb21_extra && (B[p.sfbmax] > 1 || p.block_type == D0.SHORT_TYPE && (B[p.sfbmax + 1] > 1 || B[p.sfbmax + 2] > 1)) || !U(R, p, B, d, L))
          break;
        p.scalefac_scale != 0 && (i = 254);
        var s = l - p.part2_length;
        if (s <= 0)
          break;
        for (; (p.part2_3_length = u0.count_bits(
          M,
          d,
          p,
          b
        )) > s && p.global_gain <= i; )
          p.global_gain++;
        if (p.global_gain > i)
          break;
        if (I.over_count == 0) {
          for (; (p.part2_3_length = u0.count_bits(
            M,
            d,
            p,
            b
          )) > a && p.global_gain <= i; )
            p.global_gain++;
          if (p.global_gain > i)
            break;
        }
        if (X.calc_noise(
          p,
          u,
          B,
          P,
          b
        ), P.bits = p.part2_3_length, o.block_type != D0.SHORT_TYPE ? v0 = R.quant_comp : v0 = R.quant_comp_short, v0 = O(
          v0,
          I,
          P,
          p,
          B
        ) ? 1 : 0, v0 != 0)
          a = o.part2_3_length, I = P, o.assign(p), N = 0, y1.arraycopy(d, 0, H, 0, 576);
        else if (M.full_outer_loop == 0 && (++N > E && I.over_count == 0 || M.noise_shaping_amp == 3 && L && N > 30 || M.noise_shaping_amp == 3 && L && p.global_gain - V > 15))
          break;
      } while (p.global_gain + p.scalefac_scale < 255);
      M.noise_shaping_amp == 3 ? L ? S = !0 : (p.assign(o), y1.arraycopy(H, 0, d, 0, 576), N = 0, V = p.global_gain, L = !0) : S = !0;
    }
    return U1(o.global_gain + o.scalefac_scale <= 255), R.VBR == _a.vbr_rh || R.VBR == _a.vbr_mtrh ? y1.arraycopy(H, 0, d, 0, 576) : M.substep_shaping & 1 && trancate_smallspectrums(M, o, u, d), I.over_count;
  }, this.iteration_finish_one = function(R, o, u) {
    var d = R.l3_side, e = d.tt[o][u];
    u0.best_scalefac_store(R, o, u, d), R.use_best_huffman == 1 && u0.best_huffman_divide(R, e), Z.ResvAdjust(R, e);
  }, this.VBR_encode_granule = function(R, o, u, d, e, l, M) {
    var p = R.internal_flags, H = new la(), B = K1(576), I = M, v0 = M + 1, b = (M + l) / 2, a, S, L = 0, V = p.sfb21_extra;
    U1(I <= LameInternalFlags.MAX_BITS_PER_CHANNEL), X1.fill(H.l3_enc, 0);
    do
      b > I - 42 ? p.sfb21_extra = !1 : p.sfb21_extra = V, S = outer_loop(R, o, u, d, e, b), S <= 0 ? (L = 1, v0 = o.part2_3_length, H.assign(o), y1.arraycopy(d, 0, B, 0, 576), M = v0 - 32, a = M - l, b = (M + l) / 2) : (l = b + 32, a = M - l, b = (M + l) / 2, L != 0 && (L = 2, o.assign(H), y1.arraycopy(B, 0, d, 0, 576)));
    while (a > 12);
    p.sfb21_extra = V, L == 2 && y1.arraycopy(H.l3_enc, 0, o.l3_enc, 0, 576), U1(o.part2_3_length <= I);
  }, this.get_framebits = function(R, o) {
    var u = R.internal_flags;
    u.bitrate_index = u.VBR_min_bitrate;
    var d = w.getframebits(R);
    u.bitrate_index = 1, d = w.getframebits(R);
    for (var e = 1; e <= u.VBR_max_bitrate; e++) {
      u.bitrate_index = e;
      var l = new MeanBits(d);
      o[e] = Z.ResvFrameBegin(R, l), d = l.bits;
    }
  }, this.VBR_old_prepare = function(R, o, u, d, e, l, M, p, H) {
    var B = R.internal_flags, I, v0 = 0, b = 1, a = 0;
    B.bitrate_index = B.VBR_max_bitrate;
    var S = Z.ResvFrameBegin(R, new MeanBits(0)) / B.mode_gr;
    get_framebits(R, l);
    for (var L = 0; L < B.mode_gr; L++) {
      var V = X.on_pe(R, o, p[L], S, L, 0);
      B.mode_ext == D0.MPG_MD_MS_LR && (ms_convert(B.l3_side, L), X.reduce_side(p[L], u[L], S, V));
      for (var N = 0; N < B.channels_out; ++N) {
        var P = B.l3_side.tt[L][N];
        P.block_type != D0.SHORT_TYPE ? (v0 = 1.28 / (1 + Math.exp(3.5 - o[L][N] / 300)) - 0.05, I = B.PSY.mask_adjust - v0) : (v0 = 2.56 / (1 + Math.exp(3.5 - o[L][N] / 300)) - 0.14, I = B.PSY.mask_adjust_short - v0), B.masking_lower = Math.pow(
          10,
          I * 0.1
        ), init_outer_loop(B, P), H[L][N] = X.calc_xmin(
          R,
          d[L][N],
          P,
          e[L][N]
        ), H[L][N] != 0 && (b = 0), M[L][N] = 126, a += p[L][N];
      }
    }
    for (var L = 0; L < B.mode_gr; L++)
      for (var N = 0; N < B.channels_out; N++)
        a > l[B.VBR_max_bitrate] && (p[L][N] *= l[B.VBR_max_bitrate], p[L][N] /= a), M[L][N] > p[L][N] && (M[L][N] = p[L][N]);
    return b;
  }, this.bitpressure_strategy = function(R, o, u, d) {
    for (var e = 0; e < R.mode_gr; e++)
      for (var l = 0; l < R.channels_out; l++) {
        for (var M = R.l3_side.tt[e][l], p = o[e][l], H = 0, B = 0; B < M.psy_lmax; B++)
          p[H++] *= 1 + 0.029 * B * B / D0.SBMAX_l / D0.SBMAX_l;
        if (M.block_type == D0.SHORT_TYPE)
          for (var B = M.sfb_smin; B < D0.SBMAX_s; B++)
            p[H++] *= 1 + 0.029 * B * B / D0.SBMAX_s / D0.SBMAX_s, p[H++] *= 1 + 0.029 * B * B / D0.SBMAX_s / D0.SBMAX_s, p[H++] *= 1 + 0.029 * B * B / D0.SBMAX_s / D0.SBMAX_s;
        d[e][l] = 0 | Math.max(
          u[e][l],
          0.9 * d[e][l]
        );
      }
  }, this.VBR_new_prepare = function(R, o, u, d, e, l) {
    var M = R.internal_flags, p = 1, H = 0, B = 0, I;
    if (R.free_format) {
      M.bitrate_index = 0;
      var v0 = new MeanBits(H);
      I = Z.ResvFrameBegin(R, v0), H = v0.bits, e[0] = I;
    } else {
      M.bitrate_index = M.VBR_max_bitrate;
      var v0 = new MeanBits(H);
      Z.ResvFrameBegin(R, v0), H = v0.bits, get_framebits(R, e), I = e[M.VBR_max_bitrate];
    }
    for (var b = 0; b < M.mode_gr; b++) {
      X.on_pe(R, o, l[b], H, b, 0), M.mode_ext == D0.MPG_MD_MS_LR && ms_convert(M.l3_side, b);
      for (var a = 0; a < M.channels_out; ++a) {
        var S = M.l3_side.tt[b][a];
        M.masking_lower = Math.pow(
          10,
          M.PSY.mask_adjust * 0.1
        ), init_outer_loop(M, S), X.calc_xmin(
          R,
          u[b][a],
          S,
          d[b][a]
        ) != 0 && (p = 0), B += l[b][a];
      }
    }
    for (var b = 0; b < M.mode_gr; b++)
      for (var a = 0; a < M.channels_out; a++)
        B > I && (l[b][a] *= I, l[b][a] /= B);
    return p;
  }, this.calc_target_bits = function(R, o, u, d, e, l) {
    var M = R.internal_flags, p = M.l3_side, H, B, I, v0, b = 0;
    M.bitrate_index = M.VBR_max_bitrate;
    var a = new MeanBits(b);
    for (l[0] = Z.ResvFrameBegin(R, a), b = a.bits, M.bitrate_index = 1, b = w.getframebits(R) - M.sideinfo_len * 8, e[0] = b / (M.mode_gr * M.channels_out), b = R.VBR_mean_bitrate_kbps * R.framesize * 1e3, M.substep_shaping & 1 && (b *= 1.09), b /= R.out_samplerate, b -= M.sideinfo_len * 8, b /= M.mode_gr * M.channels_out, H = 0.93 + 0.07 * (11 - R.compression_ratio) / (11 - 5.5), H < 0.9 && (H = 0.9), H > 1 && (H = 1), B = 0; B < M.mode_gr; B++) {
      var S = 0;
      for (I = 0; I < M.channels_out; I++) {
        if (d[B][I] = int(H * b), o[B][I] > 700) {
          var L = int((o[B][I] - 700) / 1.4), V = p.tt[B][I];
          d[B][I] = int(H * b), V.block_type == D0.SHORT_TYPE && L < b / 2 && (L = b / 2), L > b * 3 / 2 ? L = b * 3 / 2 : L < 0 && (L = 0), d[B][I] += L;
        }
        d[B][I] > LameInternalFlags.MAX_BITS_PER_CHANNEL && (d[B][I] = LameInternalFlags.MAX_BITS_PER_CHANNEL), S += d[B][I];
      }
      if (S > LameInternalFlags.MAX_BITS_PER_GRANULE)
        for (I = 0; I < M.channels_out; ++I)
          d[B][I] *= LameInternalFlags.MAX_BITS_PER_GRANULE, d[B][I] /= S;
    }
    if (M.mode_ext == D0.MPG_MD_MS_LR)
      for (B = 0; B < M.mode_gr; B++)
        X.reduce_side(
          d[B],
          u[B],
          b * M.channels_out,
          LameInternalFlags.MAX_BITS_PER_GRANULE
        );
    for (v0 = 0, B = 0; B < M.mode_gr; B++)
      for (I = 0; I < M.channels_out; I++)
        d[B][I] > LameInternalFlags.MAX_BITS_PER_CHANNEL && (d[B][I] = LameInternalFlags.MAX_BITS_PER_CHANNEL), v0 += d[B][I];
    if (v0 > l[0])
      for (B = 0; B < M.mode_gr; B++)
        for (I = 0; I < M.channels_out; I++)
          d[B][I] *= l[0], d[B][I] /= v0;
  };
}
var P2 = $2, Z2 = Q0, oa = Z2.assert;
function K2() {
  var w;
  this.setModules = function(Z) {
    w = Z;
  }, this.ResvFrameBegin = function(Z, X) {
    var z = Z.internal_flags, u0, W = z.l3_side, Q = w.getframebits(Z);
    X.bits = (Q - z.sideinfo_len * 8) / z.mode_gr;
    var D = 8 * 256 * z.mode_gr - 8;
    Z.brate > 320 ? u0 = 8 * int(Z.brate * 1e3 / (Z.out_samplerate / 1152) / 8 + 0.5) : (u0 = 8 * 1440, Z.strict_ISO && (u0 = 8 * int(32e4 / (Z.out_samplerate / 1152) / 8 + 0.5))), z.ResvMax = u0 - Q, z.ResvMax > D && (z.ResvMax = D), (z.ResvMax < 0 || Z.disable_reservoir) && (z.ResvMax = 0);
    var g = X.bits * z.mode_gr + Math.min(z.ResvSize, z.ResvMax);
    return g > u0 && (g = u0), oa(z.ResvMax % 8 == 0), oa(z.ResvMax >= 0), W.resvDrain_pre = 0, z.pinfo != null && (z.pinfo.mean_bits = X.bits / 2, z.pinfo.resvsize = z.ResvSize), g;
  }, this.ResvMaxBits = function(Z, X, z, u0) {
    var W = Z.internal_flags, Q, D = W.ResvSize, g = W.ResvMax;
    u0 != 0 && (D += X), W.substep_shaping & 1 && (g *= 0.9), z.bits = X, D * 10 > g * 9 ? (Q = D - g * 9 / 10, z.bits += Q, W.substep_shaping |= 128) : (Q = 0, W.substep_shaping &= 127, !Z.disable_reservoir && !(W.substep_shaping & 1) && (z.bits -= 0.1 * X));
    var f0 = D < W.ResvMax * 6 / 10 ? D : W.ResvMax * 6 / 10;
    return f0 -= Q, f0 < 0 && (f0 = 0), f0;
  }, this.ResvAdjust = function(Z, X) {
    Z.ResvSize -= X.part2_3_length + X.part2_length;
  }, this.ResvFrameEnd = function(Z, X) {
    var z, u0 = Z.l3_side;
    Z.ResvSize += X * Z.mode_gr;
    var W = 0;
    u0.resvDrain_post = 0, u0.resvDrain_pre = 0, (z = Z.ResvSize % 8) != 0 && (W += z), z = Z.ResvSize - W - Z.ResvMax, z > 0 && (W += z);
    {
      var Q = Math.min(u0.main_data_begin * 8, W) / 8;
      u0.resvDrain_pre += 8 * Q, W -= 8 * Q, Z.ResvSize -= 8 * Q, u0.main_data_begin -= Q;
    }
    u0.resvDrain_post += W, Z.ResvSize -= W;
  };
}
var U2 = K2;
function Q2() {
  var w = "http://www.mp3dev.org/", Z = 3, X = 98, z = 4, u0 = 0, W = 93;
  this.getLameVersion = function() {
    return Z + "." + X + "." + z;
  }, this.getLameShortVersion = function() {
    return Z + "." + X + "." + z;
  }, this.getLameVeryShortVersion = function() {
    return "LAME" + Z + "." + X + "r";
  }, this.getPsyVersion = function() {
    return u0 + "." + W;
  }, this.getLameUrl = function() {
    return w;
  }, this.getLameOsBitness = function() {
    return "32bits";
  };
}
var W2 = Q2, D1 = Q0, j2 = D1.System, Ie = D1.VbrMode, ha = D1.ShortBlock, z2 = D1.Arrays, te = D1.new_byte, J2 = D1.assert;
Q1.NUMTOCENTRIES = 100;
Q1.MAXFRAMESIZE = 2880;
function Q1() {
  var w, Z, X;
  this.setModules = function(b, a, S) {
    w = b, Z = a, X = S;
  };
  var z = 1, u0 = 2, W = 4, Q = 8, D = Q1.NUMTOCENTRIES, g = Q1.MAXFRAMESIZE, f0 = D + 4 + 4 + 4 + 4 + 4, A = f0 + 9 + 1 + 1 + 8 + 1 + 1 + 3 + 1 + 1 + 2 + 4 + 2 + 2, m = 128, O = 64, s0 = 32, K = null, t0 = "Xing", U = "Info", R = [
    0,
    49345,
    49537,
    320,
    49921,
    960,
    640,
    49729,
    50689,
    1728,
    1920,
    51009,
    1280,
    50625,
    50305,
    1088,
    52225,
    3264,
    3456,
    52545,
    3840,
    53185,
    52865,
    3648,
    2560,
    51905,
    52097,
    2880,
    51457,
    2496,
    2176,
    51265,
    55297,
    6336,
    6528,
    55617,
    6912,
    56257,
    55937,
    6720,
    7680,
    57025,
    57217,
    8e3,
    56577,
    7616,
    7296,
    56385,
    5120,
    54465,
    54657,
    5440,
    55041,
    6080,
    5760,
    54849,
    53761,
    4800,
    4992,
    54081,
    4352,
    53697,
    53377,
    4160,
    61441,
    12480,
    12672,
    61761,
    13056,
    62401,
    62081,
    12864,
    13824,
    63169,
    63361,
    14144,
    62721,
    13760,
    13440,
    62529,
    15360,
    64705,
    64897,
    15680,
    65281,
    16320,
    16e3,
    65089,
    64001,
    15040,
    15232,
    64321,
    14592,
    63937,
    63617,
    14400,
    10240,
    59585,
    59777,
    10560,
    60161,
    11200,
    10880,
    59969,
    60929,
    11968,
    12160,
    61249,
    11520,
    60865,
    60545,
    11328,
    58369,
    9408,
    9600,
    58689,
    9984,
    59329,
    59009,
    9792,
    8704,
    58049,
    58241,
    9024,
    57601,
    8640,
    8320,
    57409,
    40961,
    24768,
    24960,
    41281,
    25344,
    41921,
    41601,
    25152,
    26112,
    42689,
    42881,
    26432,
    42241,
    26048,
    25728,
    42049,
    27648,
    44225,
    44417,
    27968,
    44801,
    28608,
    28288,
    44609,
    43521,
    27328,
    27520,
    43841,
    26880,
    43457,
    43137,
    26688,
    30720,
    47297,
    47489,
    31040,
    47873,
    31680,
    31360,
    47681,
    48641,
    32448,
    32640,
    48961,
    32e3,
    48577,
    48257,
    31808,
    46081,
    29888,
    30080,
    46401,
    30464,
    47041,
    46721,
    30272,
    29184,
    45761,
    45953,
    29504,
    45313,
    29120,
    28800,
    45121,
    20480,
    37057,
    37249,
    20800,
    37633,
    21440,
    21120,
    37441,
    38401,
    22208,
    22400,
    38721,
    21760,
    38337,
    38017,
    21568,
    39937,
    23744,
    23936,
    40257,
    24320,
    40897,
    40577,
    24128,
    23040,
    39617,
    39809,
    23360,
    39169,
    22976,
    22656,
    38977,
    34817,
    18624,
    18816,
    35137,
    19200,
    35777,
    35457,
    19008,
    19968,
    36545,
    36737,
    20288,
    36097,
    19904,
    19584,
    35905,
    17408,
    33985,
    34177,
    17728,
    34561,
    18368,
    18048,
    34369,
    33281,
    17088,
    17280,
    33601,
    16640,
    33217,
    32897,
    16448
  ];
  function o(b, a) {
    if (b.nVbrNumFrames++, b.sum += a, b.seen++, !(b.seen < b.want) && (b.pos < b.size && (b.bag[b.pos] = b.sum, b.pos++, b.seen = 0), b.pos == b.size)) {
      for (var S = 1; S < b.size; S += 2)
        b.bag[S / 2] = b.bag[S];
      b.want *= 2, b.pos /= 2;
    }
  }
  function u(b, a) {
    if (!(b.pos <= 0))
      for (var S = 1; S < D; ++S) {
        var L = S / D, V, N, P = 0 | Math.floor(L * b.pos);
        P > b.pos - 1 && (P = b.pos - 1), V = b.bag[P], N = b.sum;
        var E = 0 | 256 * V / N;
        E > 255 && (E = 255), a[S] = 255 & E;
      }
  }
  this.addVbrFrame = function(b) {
    var a = b.internal_flags, S = Tables.bitrate_table[b.version][a.bitrate_index];
    J2(a.VBR_seek_table.bag != null), o(a.VBR_seek_table, S);
  };
  function d(b, a) {
    var S = b[a + 0] & 255;
    return S <<= 8, S |= b[a + 1] & 255, S <<= 8, S |= b[a + 2] & 255, S <<= 8, S |= b[a + 3] & 255, S;
  }
  function e(b, a, S) {
    b[a + 0] = 255 & (S >> 24 & 255), b[a + 1] = 255 & (S >> 16 & 255), b[a + 2] = 255 & (S >> 8 & 255), b[a + 3] = 255 & (S & 255);
  }
  function l(b, a, S) {
    b[a + 0] = 255 & (S >> 8 & 255), b[a + 1] = 255 & (S & 255);
  }
  function M(b, a) {
    return new String(b, a, t0.length(), K).equals(t0) || new String(b, a, U.length(), K).equals(U);
  }
  function p(b, a, S) {
    return 255 & (b << a | S & ~(-1 << a));
  }
  function H(b, a) {
    var S = b.internal_flags;
    a[0] = p(a[0], 8, 255), a[1] = p(a[1], 3, 7), a[1] = p(
      a[1],
      1,
      b.out_samplerate < 16e3 ? 0 : 1
    ), a[1] = p(a[1], 1, b.version), a[1] = p(a[1], 2, 4 - 3), a[1] = p(a[1], 1, b.error_protection ? 0 : 1), a[2] = p(a[2], 4, S.bitrate_index), a[2] = p(a[2], 2, S.samplerate_index), a[2] = p(a[2], 1, 0), a[2] = p(a[2], 1, b.extension), a[3] = p(a[3], 2, b.mode.ordinal()), a[3] = p(a[3], 2, S.mode_ext), a[3] = p(a[3], 1, b.copyright), a[3] = p(a[3], 1, b.original), a[3] = p(a[3], 2, b.emphasis), a[0] = 255;
    var L = 255 & (a[1] & 241), V;
    b.version == 1 ? V = m : b.out_samplerate < 16e3 ? V = s0 : V = O, b.VBR == Ie.vbr_off && (V = b.brate);
    var N;
    b.free_format ? N = 0 : N = 255 & 16 * w.BitrateIndex(
      V,
      b.version,
      b.out_samplerate
    ), b.version == 1 ? (a[1] = 255 & (L | 10), L = 255 & (a[2] & 13), a[2] = 255 & (N | L)) : (a[1] = 255 & (L | 2), L = 255 & (a[2] & 13), a[2] = 255 & (N | L));
  }
  this.getVbrTag = function(b) {
    var a = new VBRTagData(), S = 0;
    a.flags = 0;
    var L = b[S + 1] >> 3 & 1, V = b[S + 2] >> 2 & 3, N = b[S + 3] >> 6 & 3, P = b[S + 2] >> 4 & 15;
    if (P = Tables.bitrate_table[L][P], b[S + 1] >> 4 == 14 ? a.samprate = Tables.samplerate_table[2][V] : a.samprate = Tables.samplerate_table[L][V], L != 0 ? N != 3 ? S += 32 + 4 : S += 17 + 4 : N != 3 ? S += 17 + 4 : S += 9 + 4, !M(b, S))
      return null;
    S += 4, a.hId = L;
    var E = a.flags = d(b, S);
    if (S += 4, E & z && (a.frames = d(b, S), S += 4), E & u0 && (a.bytes = d(b, S), S += 4), E & W) {
      if (a.toc != null)
        for (var i = 0; i < D; i++)
          a.toc[i] = b[S + i];
      S += D;
    }
    a.vbrScale = -1, E & Q && (a.vbrScale = d(b, S), S += 4), a.headersize = (L + 1) * 72e3 * P / a.samprate, S += 21;
    var s = b[S + 0] << 4;
    s += b[S + 1] >> 4;
    var r = (b[S + 1] & 15) << 8;
    return r += b[S + 2] & 255, (s < 0 || s > 3e3) && (s = -1), (r < 0 || r > 3e3) && (r = -1), a.encDelay = s, a.encPadding = r, a;
  }, this.InitVbrTag = function(b) {
    var a = b.internal_flags, S;
    b.version == 1 ? S = m : b.out_samplerate < 16e3 ? S = s0 : S = O, b.VBR == Ie.vbr_off && (S = b.brate);
    var L = (b.version + 1) * 72e3 * S / b.out_samplerate, V = a.sideinfo_len + A;
    if (a.VBR_seek_table.TotalFrameSize = L, L < V || L > g) {
      b.bWriteVbrTag = !1;
      return;
    }
    a.VBR_seek_table.nVbrNumFrames = 0, a.VBR_seek_table.nBytesWritten = 0, a.VBR_seek_table.sum = 0, a.VBR_seek_table.seen = 0, a.VBR_seek_table.want = 1, a.VBR_seek_table.pos = 0, a.VBR_seek_table.bag == null && (a.VBR_seek_table.bag = new int[400](), a.VBR_seek_table.size = 400);
    var N = te(g);
    H(b, N);
    for (var P = a.VBR_seek_table.TotalFrameSize, E = 0; E < P; ++E)
      Z.add_dummy_byte(b, N[E] & 255, 1);
  };
  function B(b, a) {
    var S = a ^ b;
    return a = a >> 8 ^ R[S & 255], a;
  }
  this.updateMusicCRC = function(b, a, S, L) {
    for (var V = 0; V < L; ++V)
      b[0] = B(a[S + V], b[0]);
  };
  function I(b, a, S, L, V) {
    var N = b.internal_flags, P = 0, E = b.encoder_delay, i = b.encoder_padding, s = 100 - 10 * b.VBR_q - b.quality, r = X.getLameVeryShortVersion(), n, f = 0, Y, J = [1, 5, 3, 2, 4, 0, 3], T = 0 | (b.lowpassfreq / 100 + 0.5 > 255 ? 255 : b.lowpassfreq / 100 + 0.5), q = 0, i0 = 0, h0 = 0, d0 = b.internal_flags.noise_shaping, M0 = 0, R0 = 0, A0 = 0, w0 = 0, $0 = 0, f1 = (b.exp_nspsytune & 1) != 0, t = (b.exp_nspsytune & 2) != 0, _ = !1, S0 = !1, E0 = b.internal_flags.nogap_total, V0 = b.internal_flags.nogap_current, H0 = b.ATHtype, y0 = 0, T0;
    switch (b.VBR) {
      case vbr_abr:
        T0 = b.VBR_mean_bitrate_kbps;
        break;
      case vbr_off:
        T0 = b.brate;
        break;
      default:
        T0 = b.VBR_min_bitrate_kbps;
    }
    switch (b.VBR.ordinal() < J.length ? n = J[b.VBR.ordinal()] : n = 0, Y = 16 * f + n, N.findReplayGain && (N.RadioGain > 510 && (N.RadioGain = 510), N.RadioGain < -510 && (N.RadioGain = -510), i0 = 8192, i0 |= 3072, N.RadioGain >= 0 ? i0 |= N.RadioGain : (i0 |= 512, i0 |= -N.RadioGain)), N.findPeakSample && (q = Math.abs(0 | N.PeakSample / 32767 * Math.pow(2, 23) + 0.5)), E0 != -1 && (V0 > 0 && (S0 = !0), V0 < E0 - 1 && (_ = !0)), y0 = H0 + ((f1 ? 1 : 0) << 4) + ((t ? 1 : 0) << 5) + ((_ ? 1 : 0) << 6) + ((S0 ? 1 : 0) << 7), s < 0 && (s = 0), b.mode) {
      case MONO:
        M0 = 0;
        break;
      case STEREO:
        M0 = 1;
        break;
      case DUAL_CHANNEL:
        M0 = 2;
        break;
      case JOINT_STEREO:
        b.force_ms ? M0 = 4 : M0 = 3;
        break;
      case NOT_SET:
      default:
        M0 = 7;
        break;
    }
    b.in_samplerate <= 32e3 ? A0 = 0 : b.in_samplerate == 48e3 ? A0 = 2 : b.in_samplerate > 48e3 ? A0 = 3 : A0 = 1, (b.short_blocks == ha.short_block_forced || b.short_blocks == ha.short_block_dispensed || b.lowpassfreq == -1 && b.highpassfreq == -1 || /* "-k" */
    b.scale_left < b.scale_right || b.scale_left > b.scale_right || b.disable_reservoir && b.brate < 320 || b.noATH || b.ATHonly || H0 == 0 || b.in_samplerate <= 32e3) && (R0 = 1), w0 = d0 + (M0 << 2) + (R0 << 5) + (A0 << 6), $0 = N.nMusicCRC, e(S, L + P, s), P += 4;
    for (var F0 = 0; F0 < 9; F0++)
      S[L + P + F0] = 255 & r.charAt(F0);
    P += 9, S[L + P] = 255 & Y, P++, S[L + P] = 255 & T, P++, e(
      S,
      L + P,
      q
    ), P += 4, l(
      S,
      L + P,
      i0
    ), P += 2, l(
      S,
      L + P,
      h0
    ), P += 2, S[L + P] = 255 & y0, P++, T0 >= 255 ? S[L + P] = 255 : S[L + P] = 255 & T0, P++, S[L + P] = 255 & E >> 4, S[L + P + 1] = 255 & (E << 4) + (i >> 8), S[L + P + 2] = 255 & i, P += 3, S[L + P] = 255 & w0, P++, S[L + P++] = 0, l(S, L + P, b.preset), P += 2, e(S, L + P, a), P += 4, l(S, L + P, $0), P += 2;
    for (var I0 = 0; I0 < P; I0++)
      V = B(S[L + I0], V);
    return l(S, L + P, V), P += 2, P;
  }
  function v0(b) {
    b.seek(0);
    var a = te(10);
    b.readFully(a);
    var S;
    return new String(a, "ISO-8859-1").startsWith("ID3") ? S = 0 : S = ((a[6] & 127) << 21 | (a[7] & 127) << 14 | (a[8] & 127) << 7 | a[9] & 127) + a.length, S;
  }
  this.getLameTagFrame = function(b, a) {
    var S = b.internal_flags;
    if (!b.bWriteVbrTag || S.Class_ID != Lame.LAME_ID || S.VBR_seek_table.pos <= 0)
      return 0;
    if (a.length < S.VBR_seek_table.TotalFrameSize)
      return S.VBR_seek_table.TotalFrameSize;
    z2.fill(a, 0, S.VBR_seek_table.TotalFrameSize, 0), H(b, a);
    var L = te(D);
    if (b.free_format)
      for (var V = 1; V < D; ++V)
        L[V] = 255 & 255 * V / 100;
    else
      u(S.VBR_seek_table, L);
    var N = S.sideinfo_len;
    b.error_protection && (N -= 2), b.VBR == Ie.vbr_off ? (a[N++] = 255 & U.charAt(0), a[N++] = 255 & U.charAt(1), a[N++] = 255 & U.charAt(2), a[N++] = 255 & U.charAt(3)) : (a[N++] = 255 & t0.charAt(0), a[N++] = 255 & t0.charAt(1), a[N++] = 255 & t0.charAt(2), a[N++] = 255 & t0.charAt(3)), e(a, N, z + u0 + W + Q), N += 4, e(a, N, S.VBR_seek_table.nVbrNumFrames), N += 4;
    var P = S.VBR_seek_table.nBytesWritten + S.VBR_seek_table.TotalFrameSize;
    e(a, N, 0 | P), N += 4, j2.arraycopy(L, 0, a, N, L.length), N += L.length, b.error_protection && Z.CRC_writeheader(S, a);
    for (var E = 0, V = 0; V < N; V++)
      E = B(a[V], E);
    return N += I(b, P, a, N, E), S.VBR_seek_table.TotalFrameSize;
  }, this.putVbrTag = function(b, a) {
    var S = b.internal_flags;
    if (S.VBR_seek_table.pos <= 0 || (a.seek(a.length()), a.length() == 0))
      return -1;
    var L = v0(a);
    a.seek(L);
    var V = te(g), N = getLameTagFrame(b, V);
    return N > V.length ? -1 : (N < 1 || a.write(V, 0, N), 0);
  };
}
var g2 = Q1, Fa = Q0, ua = Fa.new_byte, er = Fa.assert, ar = Oe(), rr = V2, tr = Na, sr = Va(), ir = P2, nr = Oa(), _r = U2, lr = j1, vr = Ve();
t1();
var or = W2, hr = g2;
function ur() {
  this.setModules = function(w, Z) {
  };
}
function fr() {
  this.setModules = function(w, Z, X) {
  };
}
function mr() {
}
function br() {
  this.setModules = function(w, Z) {
  };
}
function cr(w, Z, X) {
  arguments.length != 3 && (console.error("WARN: Mp3Encoder(channels, samplerate, kbps) not specified"), w = 1, Z = 44100, X = 128);
  var z = new ar(), u0 = new ur(), W = new tr(), Q = new vr(), D = new rr(), g = new sr(), f0 = new ir(), A = new hr(), m = new or(), O = new br(), s0 = new _r(), K = new nr(), t0 = new fr(), U = new mr();
  z.setModules(W, Q, D, g, f0, A, m, O, U), Q.setModules(W, U, m, A), O.setModules(Q, m), D.setModules(z), f0.setModules(Q, s0, g, K), g.setModules(K, s0, z.enc.psy), s0.setModules(Q), K.setModules(g), A.setModules(z, Q, m), u0.setModules(t0, U), t0.setModules(m, O, D);
  var R = z.lame_init();
  R.num_channels = w, R.in_samplerate = Z, R.brate = X, R.mode = lr.STEREO, R.quality = 3, R.bWriteVbrTag = !1, R.disable_reservoir = !0, R.write_id3tag_automatic = !1, z.lame_init_params(R);
  var o = 1152, u = 0 | 1.25 * o + 7200, d = ua(u);
  this.encodeBuffer = function(e, l) {
    w == 1 && (l = e), er(e.length == l.length), e.length > o && (o = e.length, u = 0 | 1.25 * o + 7200, d = ua(u));
    var M = z.lame_encode_buffer(R, e, l, e.length, d, 0, u);
    return new Int8Array(d.subarray(0, M));
  }, this.flush = function() {
    var e = z.lame_encode_flush(R, d, 0, u);
    return new Int8Array(d.subarray(0, e));
  };
}
function A1() {
  this.dataOffset = 0, this.dataLen = 0, this.channels = 0, this.sampleRate = 0;
}
function _e(w) {
  return w.charCodeAt(0) << 24 | w.charCodeAt(1) << 16 | w.charCodeAt(2) << 8 | w.charCodeAt(3);
}
A1.RIFF = _e("RIFF");
A1.WAVE = _e("WAVE");
A1.fmt_ = _e("fmt ");
A1.data = _e("data");
A1.readHeader = function(w) {
  var Z = new A1(), X = w.getUint32(0, !1);
  if (A1.RIFF == X && (w.getUint32(4, !0), A1.WAVE == w.getUint32(8, !1) && A1.fmt_ == w.getUint32(12, !1))) {
    var z = w.getUint32(16, !0), u0 = 16 + 4;
    switch (z) {
      case 16:
      case 18:
        Z.channels = w.getUint16(u0 + 2, !0), Z.sampleRate = w.getUint32(u0 + 4, !0);
        break;
      default:
        throw "extended fmt chunk not implemented";
    }
    u0 += z;
    for (var W = A1.data, Q = 0; W != X && (X = w.getUint32(u0, !1), Q = w.getUint32(u0 + 4, !0), W != X); )
      u0 += Q + 8;
    return Z.dataLen = Q, Z.dataOffset = u0 + 8, Z;
  }
};
var Sr = fa.Mp3Encoder = cr, dr = fa.WavHeader = A1;
export {
  Sr as Mp3Encoder,
  dr as WavHeader,
  fa as default
};
