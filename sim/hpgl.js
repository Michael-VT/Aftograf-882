/**
 * Small, browser-safe HPGL parser used by the legacy simulator.
 *
 * Coordinates are kept in HPGL plotter units. PU/PD, PA and PR all update
 * the current position, so files emitted by real plotters and by the sample
 * generators follow the same state machine.
 */

const SUPPORTED_OPS = 'IN|SP|PU|PD|PA|PR';

function parseArgs(text) {
  const matches = String(text || '').match(/[+-]?\d+/g);
  return matches ? matches.map(Number) : [];
}

function pairArgs(args) {
  const pairs = [];
  for (let i = 0; i + 1 < args.length; i += 2) {
    pairs.push([args[i], args[i + 1]]);
  }
  return pairs;
}

function tokenize(text) {
  const commands = [];
  const chunks = String(text || '').replace(/\r/g, '').split(/[;\n]/);
  const opPattern = new RegExp(`(?:^|[^A-Z])((?:${SUPPORTED_OPS}))(?=$|[^A-Z])`);

  for (const rawChunk of chunks) {
    const raw = rawChunk.trim();
    if (!raw) continue;
    const match = raw.match(opPattern);
    if (!match) continue;
    const op = match[1];
    const opStart = match.index + match[0].lastIndexOf(op);
    commands.push({
      op,
      argsText: raw.slice(opStart + op.length).trim(),
      raw,
    });
  }
  return commands;
}

function buildSegments(coordinates) {
  const segments = [];
  let x = 0;
  let y = 0;

  for (const point of coordinates) {
    if (point.cmd === 'PU') {
      x = point.x;
      y = point.y;
      continue;
    }

    if (point.cmd !== 'PD') continue;
    // HPGL is a polyline language: every coordinate under PD is a
    // separate vector from the previous coordinate. Do not collapse a
    // complete PD/PA run into one diagonal segment.
    if (x !== point.x || y !== point.y) {
      segments.push({ x1: x, y1: y, x2: point.x, y2: point.y, pen: point.pen });
    }
    x = point.x;
    y = point.y;
  }
  return segments;
}

export function parseHPGL(text) {
  const commands = tokenize(text);
  const coordinates = [];
  let x = 0;
  let y = 0;
  let penDown = false;
  let penNum = 0;

  const addPoint = (nx, ny) => {
    x = nx;
    y = ny;
    coordinates.push({ x, y, cmd: penDown ? 'PD' : 'PU', pen: penNum });
  };

  for (const command of commands) {
    const args = parseArgs(command.argsText);
    switch (command.op) {
      case 'IN':
        x = 0;
        y = 0;
        penDown = false;
        break;
      case 'SP':
        penNum = Math.min(6, Math.max(0, (args[0] || 1) - 1));
        break;
      case 'PU':
        penDown = false;
        if (pairArgs(args).length === 0) {
          coordinates.push({ x, y, cmd: 'PU', pen: penNum });
        } else {
          for (const [nx, ny] of pairArgs(args)) addPoint(nx, ny);
        }
        break;
      case 'PD':
        penDown = true;
        if (pairArgs(args).length === 0) {
          coordinates.push({ x, y, cmd: 'PD', pen: penNum });
        } else {
          for (const [nx, ny] of pairArgs(args)) addPoint(nx, ny);
        }
        break;
      case 'PA':
        for (const [nx, ny] of pairArgs(args)) addPoint(nx, ny);
        break;
      case 'PR':
        for (const [dx, dy] of pairArgs(args)) addPoint(x + dx, y + dy);
        break;
      default:
        break;
    }
  }

  return {
    commands,
    coordinates,
    segments: buildSegments(coordinates),
  };
}
