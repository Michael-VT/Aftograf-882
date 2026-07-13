/// Plotter Simulation — XY stepper motors, pen control, line segments.
pub struct Plotter {
    pub x: i32,
    pub y: i32,
    pub x_pos: i32,
    pub y_pos: i32,
    pub pen_down: bool,
    pub pen_num: u8,
    pub last_x_phase: u8,
    pub last_y_phase: u8,
    pub lines: Vec<LineSegment>,
    pub current_segment: Option<LineSegment>,
    pub last_mem_pen_state: i32,
    pub last_mem_x: i32,
    pub last_mem_y: i32,
    pub last_mem_color: i32,
    pub limit_xmin: bool,
    pub limit_xmax: bool,
    pub limit_ymin: bool,
    pub limit_ymax: bool,
    pub limit_pen_up: bool,
    pub limit_pen_dn: bool,
    pub table_xmin: i32,
    pub table_xmax: i32,
    pub table_ymin: i32,
    pub table_ymax: i32,
}

#[derive(Clone, Copy)]
pub struct LineSegment {
    pub x1: i32,
    pub y1: i32,
    pub x2: i32,
    pub y2: i32,
    pub pen: u8,
}

pub const PEN_COLORS: [(&str, &str); 7] = [
    ("Чёрный",     "#000000"),
    ("Красный",    "#cc0000"),
    ("Синий",      "#0055ff"),
    ("Зелёный",    "#009900"),
    ("Жёлтый",     "#ccaa00"),
    ("Фиолетовый", "#8800cc"),
    ("Голубой",    "#0099cc"),
];

impl Plotter {
    pub fn new() -> Self {
        Plotter {
            x: 0, y: 0, x_pos: 0, y_pos: 0,
            pen_down: false, pen_num: 0,
            last_x_phase: 0, last_y_phase: 0,
            lines: Vec::new(),
            current_segment: None,
            last_mem_pen_state: -1,
            last_mem_x: -1, last_mem_y: -1, last_mem_color: -1,
            limit_xmin: false, limit_xmax: false,
            limit_ymin: false, limit_ymax: false,
            limit_pen_up: false, limit_pen_dn: false,
            table_xmin: 0, table_xmax: 17200,
            table_ymin: 0, table_ymax: 12200,
        }
    }

    pub fn check_limits(&mut self) {
        self.limit_xmin = self.x_pos <= self.table_xmin;
        self.limit_xmax = self.x_pos >= self.table_xmax;
        self.limit_ymin = self.y_pos <= self.table_ymin;
        self.limit_ymax = self.y_pos >= self.table_ymax;
    }

    /// Sync plotter state from memory variables
    pub fn sync_from_memory(&mut self, mem_x: i32, mem_y: i32, mem_pen_down: bool, mem_color: u8) {
        if mem_x != self.last_mem_x {
            self.x_pos = mem_x;
            self.x = mem_x;
            self.last_mem_x = mem_x;
        }
        if mem_y != self.last_mem_y {
            self.y_pos = mem_y;
            self.y = mem_y;
            self.last_mem_y = mem_y;
        }
        if mem_pen_down != (self.last_mem_pen_state != 0) {
            let was_down = self.pen_down;
            self.pen_down = mem_pen_down;
            self.last_mem_pen_state = if mem_pen_down { 1 } else { 0 };
            if self.pen_down && !was_down {
                self.current_segment = Some(LineSegment {
                    x1: self.x_pos, y1: self.y_pos,
                    x2: self.x_pos, y2: self.y_pos,
                    pen: self.pen_num,
                });
            } else if !self.pen_down && was_down {
                if let Some(seg) = self.current_segment.take() {
                    let mut seg = seg;
                    seg.x2 = self.x_pos;
                    seg.y2 = self.y_pos;
                    self.lines.push(seg);
                }
            }
        }
        if mem_color as i32 != self.last_mem_color {
            self.pen_num = mem_color.min(6);
            self.last_mem_color = mem_color as i32;
        }
    }

    /// Update stepper motor position from phase pattern
    pub fn update_stepper(&mut self, axis: char, phases: u8) {
        let phase = phases & 0x0F;
        if axis == 'x' {
            if self.last_x_phase != phase && self.last_x_phase != 0 {
                self.x_pos += self.step_dir(self.last_x_phase, phase);
                self.x = self.x_pos;
            }
            self.last_x_phase = phase;
        } else {
            if self.last_y_phase != phase && self.last_y_phase != 0 {
                self.y_pos += self.step_dir(self.last_y_phase, phase);
                self.y = self.y_pos;
            }
            self.last_y_phase = phase;
        }
    }

    fn step_dir(&self, prev: u8, curr: u8) -> i32 {
        const RING: [u8; 8] = [0x1, 0x3, 0x2, 0x6, 0x4, 0xC, 0x8, 0x9];
        let pi = RING.iter().position(|&x| x == prev);
        let ci = RING.iter().position(|&x| x == curr);
        match (pi, ci) {
            (Some(pi), Some(ci)) => {
                let diff = (ci as i32 - pi as i32 + 8) % 8;
                if diff == 1 || diff == 2 { 1 } else { -1 }
            }
            _ => 0,
        }
    }

    /// Set pen state from PPI2 port C
    pub fn set_pen(&mut self, ctl: u8) {
        if self.last_mem_pen_state < 0 {
            let was_down = self.pen_down;
            self.pen_down = (ctl & 0x01) == 0;
            let pn = (ctl >> 1) & 0x07;
            if pn < 7 { self.pen_num = pn; }
            if self.pen_down && !was_down {
                self.current_segment = Some(LineSegment {
                    x1: self.x_pos, y1: self.y_pos,
                    x2: self.x_pos, y2: self.y_pos,
                    pen: self.pen_num,
                });
            } else if !self.pen_down && was_down {
                if let Some(seg) = self.current_segment.take() {
                    let mut seg = seg;
                    seg.x2 = self.x_pos;
                    seg.y2 = self.y_pos;
                    self.lines.push(seg);
                }
            }
        }
    }

    pub fn update_position(&mut self) {
        if self.pen_down && self.current_segment.is_none() {
            self.current_segment = Some(LineSegment {
                x1: self.x_pos, y1: self.y_pos,
                x2: self.x_pos, y2: self.y_pos,
                pen: self.pen_num,
            });
        }
    }


    pub fn reset(&mut self) {
        self.x = 0; self.y = 0;
        self.x_pos = 0; self.y_pos = 0;
        self.pen_down = false;
        self.pen_num = 0;
        self.last_x_phase = 0; self.last_y_phase = 0;
        self.last_mem_pen_state = -1;
        self.last_mem_x = -1; self.last_mem_y = -1;
        self.last_mem_color = -1;
        self.lines.clear();
        self.current_segment = None;
    }
}
