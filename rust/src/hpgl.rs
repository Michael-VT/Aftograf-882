use crate::plotter::LineSegment;

/// HPGL Parser — commands IN, SP, PU, PD
pub struct HPGL {
    pub total_coords: usize,
    pub current: usize,
    pub paused: bool,
    pub commands: Vec<String>,
    pub coordinates: Vec<HPGLPoint>,
    pub ref_segments: Vec<LineSegment>,
    pub generated_segments: Vec<LineSegment>,
    pub hpgl_lines: Vec<String>,
    pub hpgl_render: bool,
}

#[allow(dead_code)]
#[derive(Clone)]
pub struct HPGLPoint {
    pub x: i32,
    pub y: i32,
    pub cmd: String,
    pub pen: u8,
}

#[allow(dead_code)]
impl HPGL {
    pub fn new() -> Self {
        HPGL {
            paused: false,
            commands: Vec::new(),
            total_coords: 0,
            current: 0,
            coordinates: Vec::new(),
            ref_segments: Vec::new(),
            generated_segments: Vec::new(),
            hpgl_lines: Vec::new(),
            hpgl_render: true,
        }
    }
    pub fn parse(&mut self, text: &str) {
        self.commands = text.split(';')
            .map(|s| s.trim().to_string())
            .filter(|s| !s.is_empty())
            .collect();

        let mut pen_num: u8 = 0;
        let mut min_x = i32::MAX;
        let mut max_x = i32::MIN;
        let mut min_y = i32::MAX;
        let mut max_y = i32::MIN;
        let mut coords: Vec<HPGLPoint> = Vec::new();
        let mut last_x = 0i32;
        let mut last_y = 0i32;

        for cmd in &self.commands {
            if let Some(m) = Self::parse_cmd(cmd) {
                match m.op.as_str() {
                    "SP" => {
                        if let Some(n) = m.args.first() {
                            pen_num = (*n as u8).min(6);
                        }
                    }
                    "PU" | "PD" | "PA" | "PR" => {
                        let is_pu_or_pd = m.op == "PU" || m.op == "PD";
                        if is_pu_or_pd && m.args.is_empty() {
                            coords.push(HPGLPoint {
                                x: last_x, y: last_y,
                                cmd: m.op.clone(),
                                pen: pen_num,
                            });
                        }
                        for i in (0..m.args.len()).step_by(2) {
                            if i + 1 < m.args.len() {
                                let cx = m.args[i];
                                let cy = m.args[i + 1];
                                coords.push(HPGLPoint {
                                    x: cx, y: cy,
                                    cmd: m.op.clone(),
                                    pen: pen_num,
                                });
                                last_x = cx;
                                last_y = cy;
                                min_x = min_x.min(cx);
                                max_x = max_x.max(cx);
                                min_y = min_y.min(cy);
                                max_y = max_y.max(cy);
                            }
                        }
                    }
                    _ => {}
                }
            }
        }

        self.coordinates = coords;
        self.total_coords = self.coordinates.len();
        self.current = 0;

        // Build reference segments
        self.ref_segments.clear();
        let mut ref_pen_down = false;
        let ref_pen: u8 = 0;
        let mut ref_x = 0i32;
        let mut ref_y = 0i32;
        for pt in &self.coordinates {
            if pt.cmd == "PD" && ref_pen_down {
                if let Some(last) = self.ref_segments.last_mut() {
                    if last.pen == ref_pen {
                        last.x2 = pt.x;
                        last.y2 = pt.y;
                    } else {
                        self.ref_segments.push(LineSegment {
                            x1: ref_x, y1: ref_y, x2: pt.x, y2: pt.y, pen: ref_pen,
                        });
                    }
                } else {
                    self.ref_segments.push(LineSegment {
                        x1: ref_x, y1: ref_y, x2: pt.x, y2: pt.y, pen: ref_pen,
                    });
                }
            } else if pt.cmd == "PD" && !ref_pen_down {
                ref_pen_down = true;
                self.ref_segments.push(LineSegment {
                    x1: ref_x, y1: ref_y, x2: pt.x, y2: pt.y, pen: ref_pen,
                });
            } else if pt.cmd == "PU" {
                ref_pen_down = false;
            }
            ref_x = pt.x;
            ref_y = pt.y;
        }
        // Generate line segments for the plotter

        // Format command lines for display
        self.hpgl_lines.clear();
        for (i, cmd) in self.commands.iter().enumerate() {
            let line_num = i + 1;
            // Parse to separate command from args
            let cmd_str = cmd.trim();
            let cmd_end = cmd_str.find(|c: char| !c.is_ascii_uppercase()).unwrap_or(cmd_str.len());
            if (2..=3).contains(&cmd_end) {
                let op = &cmd_str[..cmd_end];
                let args = cmd_str[cmd_end..].trim();
                self.hpgl_lines.push(format!("{line_num:06}  {op}  {args}"));
            } else {
                self.hpgl_lines.push(format!("{line_num:06}  {cmd_str}"));
            }
        }
        self.generated_segments = self.generate_segments();
    }

    /// Convert HPGL coordinates into plotter line segments
    /// following pen-up/pen-down and pen selection commands
    pub fn generate_segments(&self) -> Vec<LineSegment> {
        let mut segments = Vec::new();
        let mut last_x = 0i32;
        let mut last_y = 0i32;
        let mut pen_down = false;

        for c in &self.coordinates {
            match c.cmd.as_str() {
                "PU" => { pen_down = false; }
                "PD" => { pen_down = true; }
                _ => {}
            }
            if pen_down && (c.x != last_x || c.y != last_y) {
                segments.push(LineSegment {
                    x1: last_x, y1: last_y,
                    x2: c.x, y2: c.y,
                    pen: c.pen,
                });
            }
            last_x = c.x;
            last_y = c.y;
        }
        segments
    }
    fn parse_cmd(cmd: &str) -> Option<ParsedCmd> {
        // Parse HPGL command: 2-3 letter command, optionally followed by args
        // Commands like: PU, PD, SP1, PA100,200
        let cmd = cmd.trim();
        if cmd.is_empty() { return None; }
        
        // Find end of command (sequence of uppercase letters)
        let cmd_end = cmd.find(|c: char| !c.is_ascii_uppercase()).unwrap_or(cmd.len());
        if !(2..=3).contains(&cmd_end) { return None; }
        
        let op = cmd[..cmd_end].to_string();
        let args_str = cmd[cmd_end..].trim();
        let args: Vec<i32> = if args_str.is_empty() {
            Vec::new()
        } else {
            args_str.split([' ', ','])
                .filter(|s| !s.is_empty())
                .filter_map(|s| s.parse::<i32>().ok())
                .collect()
        };
        Some(ParsedCmd { op, args })
    }

    pub fn reset(&mut self) {
        self.total_coords = 0;
        self.current = 0;
        self.paused = false;
        self.commands.clear();
        self.coordinates.clear();
        self.ref_segments.clear();
    }
}

#[allow(dead_code)]
struct ParsedCmd {
    op: String,
    args: Vec<i32>,
}

/// Minimal regex substitute for parsing
#[allow(dead_code)]
mod regex_lite {
    pub struct Regex {
        pattern: String,
        groups: Vec<usize>,
    }

    impl Regex {
        pub fn new(pattern: &str) -> Option<Self> {
            Some(Regex {
                pattern: pattern.to_string(),
                groups: Vec::new(),
            })
        }

        pub fn captures<'t>(&self, text: &'t str) -> Option<Captures<'t>> {
            // Simple manual parse for pattern: ^([A-Z]{2,3})\s*(.*)$
            let text = text.trim();
            let mut op_end = 0;
            for (i, c) in text.char_indices() {
                if !c.is_ascii_uppercase() {
                    break;
                }
                op_end = i + 1;
            }
            if !(2..=3).contains(&op_end) {
                return None;
            }
            let op = &text[..op_end];
            let rest = text[op_end..].trim();
            Some(Captures { op, rest })
        }
    }

    pub struct Captures<'t> {
        op: &'t str,
        rest: &'t str,
    }

    impl<'t> Captures<'t> {
        pub fn get(&self, _index: usize) -> Option<&'t str> {
            match _index {
                1 => Some(self.op),
                2 => Some(self.rest),
                _ => None,
            }
        }
    }
}
