use serde::{Deserialize, Serialize};
use crate::cpu::CpuState;
use crate::plotter::LineSegment;

/// Full session state for save/load
#[derive(Serialize, Deserialize)]
pub struct Session {
    pub version: u32,
    pub date: String,
    pub cpu: CpuState,
    pub ram: Vec<u8>,
    pub breakpoints: Vec<u16>,
    pub plotter: PlotterState,
}

#[derive(Serialize, Deserialize)]
pub struct PlotterState {
    pub x_pos: i32,
    pub y_pos: i32,
    pub pen_down: bool,
    pub pen_num: u8,
    pub lines: Vec<LineSegmentState>,
}

#[derive(Serialize, Deserialize)]
pub struct LineSegmentState {
    pub x1: i32, pub y1: i32,
    pub x2: i32, pub y2: i32,
    pub pen: u8,
}

#[allow(dead_code)]
impl Session {
    pub fn new() -> Self {
        Session {
            version: 1,
            date: String::new(),
            cpu: CpuState {
                a: 0, b: 0, c: 0, d: 0, e: 0,
                h: 0, l: 0, flags: 2, sp: 0x6140, pc: 0,
                cycles: 0, halt: false, ie: false,
            },
            ram: vec![0u8; 0x0800],
            breakpoints: Vec::new(),
            plotter: PlotterState {
                x_pos: 0, y_pos: 0,
                pen_down: false, pen_num: 0,
                lines: Vec::new(),
            },
        }
    }

    /// Serialize to JSON string
    pub fn to_json(&self) -> Result<String, serde_json::Error> {
        serde_json::to_string_pretty(self)
    }

    /// Deserialize from JSON string
    pub fn from_json(json: &str) -> Result<Self, serde_json::Error> {
        serde_json::from_str(json)
    }
}

impl From<&LineSegment> for LineSegmentState {
    fn from(s: &LineSegment) -> Self {
        LineSegmentState { x1: s.x1, y1: s.y1, x2: s.x2, y2: s.y2, pen: s.pen }
    }
}

impl From<&LineSegmentState> for LineSegment {
    fn from(s: &LineSegmentState) -> Self {
        LineSegment { x1: s.x1, y1: s.y1, x2: s.x2, y2: s.y2, pen: s.pen }
    }
}
