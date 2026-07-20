import assert from 'node:assert/strict';
import { parseHPGL } from './hpgl.js';

const basic = parseHPGL('IN;SP1;PU0,0;PD;PA100,0;PA100,100;PU;');
assert.equal(basic.coordinates.length, 5);
assert.deepEqual(basic.coordinates.at(-1), { x: 100, y: 100, cmd: 'PU', pen: 0 });
assert.equal(basic.segments.length, 2);
assert.deepEqual(basic.segments[0], { x1: 0, y1: 0, x2: 100, y2: 0, pen: 0 });
assert.deepEqual(basic.segments[1], { x1: 100, y1: 0, x2: 100, y2: 100, pen: 0 });

const relative = parseHPGL('PU10,20;PD;PR5,6;PR-2,3;PU;');
assert.equal(relative.segments.length, 2);
assert.deepEqual(relative.segments[1], { x1: 15, y1: 26, x2: 13, y2: 29, pen: 0 });

const pa = parseHPGL(`IN;SP1;PU;PA1432,1234;PD;PA1432,2000,1054,2000;
  PA1054,1234;PU;PA1234,1121;PD;PA1234,87;PA361,87;PU;`);
assert.ok(pa.coordinates.length > 8, 'PA-based plotter data should produce coordinates');
assert.equal(pa.segments.length, 5);

const pd = parseHPGL('IN;SP1;PU87,25;PD79,26;PD70,29;PD63,33;PU;');
assert.equal(pd.coordinates.length, 5);
assert.equal(pd.segments.length, 3);

console.log(`HPGL tests passed: ${basic.segments.length} basic, ${pa.segments.length} PA, ${pd.segments.length} PD segments`);
