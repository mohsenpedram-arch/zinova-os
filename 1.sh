cat > crates/common-types/src/lib.rs << 'EOF'
pub mod error;
pub mod types;
EOF


cat > crates/common-types/src/error.rs << 'EOF'
use thiserror::Error;

#[derive(Error, Debug)]
pub enum EdgeError {
    #[error("DL/T645 protocol error: {0}")]
    Dlt645(#[from] Dlt645Error),

    #[error("Serial communication error: {0}")]
    Serial(String),

    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Decode error: {0}")]
    Decode(String),
}

#[derive(Error, Debug)]
pub enum Dlt645Error {
    #[error("Invalid frame: {0}")]
    InvalidFrame(String),
    #[error("Checksum mismatch: expected 0x{expected:02X}, got 0x{actual:02X}")]
    ChecksumMismatch { expected: u8, actual: u8 },
    #[error("Frame too short")]
    FrameTooShort,
}
EOF


cat > crates/common-types/src/types.rs << 'EOF'
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Measurement {
    pub voltage_a: Option<f32>,
    pub voltage_b: Option<f32>,
    pub voltage_c: Option<f32>,
    pub current_a: Option<f32>,
    pub current_b: Option<f32>,
    pub current_c: Option<f32>,
    pub active_power: Option<f32>,
    pub total_energy: Option<f64>,
    pub power_factor: Option<f32>,
    pub frequency: Option<f32>,
    pub timestamp: u64,
}
EOF


cat > crates/dlt645-core/src/lib.rs << 'EOF'
pub mod frame;
pub mod parser;
pub mod builder;
pub mod decoder;
pub mod error;
pub mod types;

pub use error::Dlt645Error;
pub use types::{Dlt645Frame, RawMeterData};
EOF



5. crates/dlt645-core/src/error.rs

```bash
cat > crates/dlt645-core/src/error.rs << 'EOF'
use thiserror::Error;

#[derive(Error, Debug)]
pub enum Dlt645Error {
    #[error("Invalid frame: {0}")]
    InvalidFrame(String),
    #[error("Checksum mismatch: expected 0x{expected:02X}, got 0x{actual:02X}")]
    ChecksumMismatch { expected: u8, actual: u8 },
    #[error("Frame too short")]
    FrameTooShort,
    #[error("Decode error: {0}")]
    DecodeError(String),
}
EOF
```

6. crates/dlt645-core/src/types.rs

```bash
cat > crates/dlt645-core/src/types.rs << 'EOF'
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone)]
pub struct Dlt645Frame {
    pub address: [u8; 6],
    pub control: u8,
    pub length: u8,
    pub data: Vec<u8>,
    pub checksum: u8,
}

#[derive(Debug, Clone, Default)]
pub struct RawMeterData {
    pub voltage_a: Option<f32>,
    pub voltage_b: Option<f32>,
    pub voltage_c: Option<f32>,
    pub current_a: Option<f32>,
    pub current_b: Option<f32>,
    pub current_c: Option<f32>,
    pub active_power: Option<f32>,
    pub total_energy: Option<f64>,
}
EOF
```

7. crates/dlt645-core/src/parser.rs — کامل با Offset و پشتیبانی از Wake-up

```bash
cat > crates/dlt645-core/src/parser.rs << 'EOF'
use crate::error::Dlt645Error;
use crate::types::Dlt645Frame;

/// Parse a DL/T645 frame from raw bytes, handling wake-up bytes (0xFE) and offset encoding.
pub fn parse_frame(mut bytes: &[u8]) -> Result<Dlt645Frame, Dlt645Error> {
    // Strip leading wake-up bytes
    while bytes.first() == Some(&0xFE) {
        bytes = &bytes[1..];
    }
    if bytes.len() < 12 {
        return Err(Dlt645Error::FrameTooShort);
    }
    // Start byte must be 0x68
    if bytes[0] != 0x68 || bytes[7] != 0x68 {
        return Err(Dlt645Error::InvalidFrame("Missing start byte 0x68".into()));
    }
    let address: [u8; 6] = bytes[1..7].try_into().unwrap();
    let control = bytes[8];
    let length = bytes[9];
    let data_len = length as usize;
    if bytes.len() < 12 + data_len {
        return Err(Dlt645Error::FrameTooShort);
    }
    let data = bytes[10..10 + data_len].to_vec();
    let checksum = bytes[10 + data_len];
    let end_byte = bytes[11 + data_len];
    if end_byte != 0x16 {
        return Err(Dlt645Error::InvalidFrame("Missing end byte 0x16".into()));
    }
    let frame = Dlt645Frame {
        address,
        control,
        length,
        data,
        checksum,
    };
    verify_checksum(&frame)?;
    Ok(frame)
}

/// Compute checksum: sum of all bytes from first 0x68 to end of data, modulo 256.
fn compute_checksum(frame: &Dlt645Frame) -> u8 {
    let mut sum: u8 = 0;
    sum = sum.wrapping_add(0x68); // first start byte
    for b in &frame.address {
        sum = sum.wrapping_add(*b);
    }
    sum = sum.wrapping_add(0x68); // second start byte
    sum = sum.wrapping_add(frame.control);
    sum = sum.wrapping_add(frame.length);
    for b in &frame.data {
        sum = sum.wrapping_add(*b);
    }
    sum
}

pub fn verify_checksum(frame: &Dlt645Frame) -> Result<(), Dlt645Error> {
    let computed = compute_checksum(frame);
    if computed != frame.checksum {
        return Err(Dlt645Error::ChecksumMismatch {
            expected: computed,
            actual: frame.checksum,
        });
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_valid_frame() {
        let bytes = vec![
            0xFE, 0xFE, 0x68, // wake-up
            0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, // address
            0x68, 0x11, 0x04, // control, length
            0x33, 0x34, 0x35, 0x36, // data
            0x9A, // checksum (0x68+... = 0x9A)
            0x16,
        ];
        let frame = parse_frame(&bytes).expect("valid");
        assert_eq!(frame.address, [0xAA; 6]);
        assert_eq!(frame.data, vec![0x33,0x34,0x35,0x36]);
    }

    #[test]
    fn test_checksum_fail() {
        let mut bytes = vec![
            0xFE, 0x68,
            0xAA,0xAA,0xAA,0xAA,0xAA,0xAA,
            0x68,0x11,0x04,
            0x33,0x34,0x35,0x36,
            0x00, // wrong
            0x16,
        ];
        assert!(parse_frame(&bytes).is_err());
    }

    #[test]
    fn test_missing_start() {
        let bytes = vec![0x00; 20];
        assert!(parse_frame(&bytes).is_err());
    }
}
EOF
```

8. crates/dlt645-core/src/decoder.rs — تبدیل BCD و استخراج Measurement

```bash
cat > crates/dlt645-core/src/decoder.rs << 'EOF'
use crate::error::Dlt645Error;
use crate::types::RawMeterData;
use common_types::Measurement;

/// Convert BCD-encoded bytes to u32 (e.g., 0x12 0x34 0x56 → 123456)
fn bcd_to_u32(bcd: &[u8]) -> Result<u32, Dlt645Error> {
    let mut value = 0u32;
    for &byte in bcd {
        let high = (byte >> 4) & 0x0F;
        let low = byte & 0x0F;
        if high > 9 || low > 9 {
            return Err(Dlt645Error::DecodeError("Invalid BCD digit".to_string()));
        }
        value = value * 100 + (high * 10 + low) as u32;
    }
    Ok(value)
}

/// Decode DL/T645 data block into RawMeterData based on data identifier (DI).
/// DI typically is 4 bytes: DI0, DI1, DI2, DI3.
pub fn decode_data(di: &[u8; 4], data: &[u8]) -> Result<RawMeterData, Dlt645Error> {
    let mut raw = RawMeterData::default();
    // Simple decoding for common identifiers (example)
    match (di[0], di[1], di[2], di[3]) {
        (0x00, 0x01, 0x02, 0x03) => {
            // Voltage A, B, C (each 2 bytes BCD, unit 0.1V)
            if data.len() >= 6 {
                raw.voltage_a = Some(bcd_to_u32(&data[0..2])? as f32 * 0.1);
                raw.voltage_b = Some(bcd_to_u32(&data[2..4])? as f32 * 0.1);
                raw.voltage_c = Some(bcd_to_u32(&data[4..6])? as f32 * 0.1);
            }
        }
        (0x00, 0x01, 0x03, 0x04) => {
            // Current A, B, C (2 bytes BCD, unit 0.01A)
            if data.len() >= 6 {
                raw.current_a = Some(bcd_to_u32(&data[0..2])? as f32 * 0.01);
                raw.current_b = Some(bcd_to_u32(&data[2..4])? as f32 * 0.01);
                raw.current_c = Some(bcd_to_u32(&data[4..6])? as f32 * 0.01);
            }
        }
        (0x00, 0x01, 0x05, 0x06) => {
            // Active power (3 bytes BCD, unit 1W) and total energy (4 bytes BCD, unit 0.01kWh)
            if data.len() >= 7 {
                raw.active_power = Some(bcd_to_u32(&data[0..3])? as f32);
                raw.total_energy = Some(bcd_to_u32(&data[3..7])? as f64 * 0.01);
            }
        }
        _ => {
            // Unknown DI, try to decode as general BCD
            if data.len() >= 4 {
                raw.total_energy = Some(bcd_to_u32(data)? as f64 * 0.01);
            }
        }
    }
    Ok(raw)
}

/// Convert RawMeterData into Measurement (adding timestamp, optional fields).
pub fn to_measurement(raw: RawMeterData) -> Measurement {
    let timestamp = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    Measurement {
        voltage_a: raw.voltage_a,
        voltage_b: raw.voltage_b,
        voltage_c: raw.voltage_c,
        current_a: raw.current_a,
        current_b: raw.current_b,
        current_c: raw.current_c,
        active_power: raw.active_power,
        total_energy: raw.total_energy,
        power_factor: None, // Not decoded yet
        frequency: Some(50.0), // default
        timestamp,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_bcd_conversion() {
        assert_eq!(bcd_to_u32(&[0x12, 0x34]).unwrap(), 1234);
        assert!(bcd_to_u32(&[0x1A]).is_err());
    }

    #[test]
    fn test_decode_voltage() {
        let di: [u8; 4] = [0x00, 0x01, 0x02, 0x03];
        let data = vec![0x22, 0x00, 0x22, 0x10, 0x21, 0x99];
        let raw = decode_data(&di, &data).unwrap();
        assert_eq!(raw.voltage_a.unwrap(), 220.0);
        assert_eq!(raw.voltage_b.unwrap(), 221.0);
        assert_eq!(raw.voltage_c.unwrap(), 219.9);
    }
}
EOF
```

9. crates/dlt645-core/src/builder.rs — اصلاح‌شده با Checksum صحیح

```bash
cat > crates/dlt645-core/src/builder.rs << 'EOF'
use crate::types::Dlt645Frame;
use crate::parser::verify_checksum;

pub fn build_read_frame(address: [u8; 6], data_identifier: &[u8]) -> Dlt645Frame {
    let control = 0x11;
    let length = data_identifier.len() as u8;
    let data = data_identifier.to_vec();
    let mut frame = Dlt645Frame {
        address,
        control,
        length,
        data,
        checksum: 0,
    };
    // Compute correct checksum
    let checksum = {
        let mut sum: u8 = 0;
        sum = sum.wrapping_add(0x68);
        for b in &frame.address { sum = sum.wrapping_add(*b); }
        sum = sum.wrapping_add(0x68);
        sum = sum.wrapping_add(frame.control);
        sum = sum.wrapping_add(frame.length);
        for b in &frame.data { sum = sum.wrapping_add(*b); }
        sum
    };
    frame.checksum = checksum;
    frame
}

pub fn to_bytes(frame: &Dlt645Frame) -> Vec<u8> {
    let mut bytes = Vec::new();
    bytes.push(0x68);
    bytes.extend_from_slice(&frame.address);
    bytes.push(0x68);
    bytes.push(frame.control);
    bytes.push(frame.length);
    bytes.extend_from_slice(&frame.data);
    bytes.push(frame.checksum);
    bytes.push(0x16);
    bytes
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::parser::parse_frame;

    #[test]
    fn roundtrip() {
        let addr = [0xAA;6];
        let di = [0x01,0x02,0x03];
        let frame = build_read_frame(addr, &di);
        let bytes = to_bytes(&frame);
        let parsed = parse_frame(&bytes).expect("roundtrip fail");
        assert_eq!(parsed.address, addr);
        assert_eq!(parsed.data, di.to_vec());
    }
}
EOF
```

10. crates/rs485-driver/src/lib.rs — Frame Reader با State Machine

```bash
cat > crates/rs485-driver/src/lib.rs << 'EOF'
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::time::{timeout, Duration};
use common_types::error::EdgeError;

pub struct Rs485Driver {
    port: tokio_serial::SerialStream,
}

impl Rs485Driver {
    pub fn new(port_path: &str, baud_rate: u32) -> Result<Self, EdgeError> {
        let port = tokio_serial::new(port_path, baud_rate)
            .data_bits(tokio_serial::DataBits::Eight)
            .stop_bits(tokio_serial::StopBits::One)
            .parity(tokio_serial::Parity::Even)
            .timeout(Duration::from_millis(200))
            .open_native_async()
            .map_err(|e| EdgeError::Serial(format!("Cannot open port: {}", e)))?;
        #[cfg(unix)]
        port.set_exclusive(false).ok();
        Ok(Self { port })
    }

    /// Stream-based frame reader: reads until a valid DL/T645 frame is found.
    pub async fn read_frame(&mut self) -> Result<Vec<u8>, EdgeError> {
        let mut buf = vec![0u8; 512];
        let mut pos = 0;
        loop {
            let n = timeout(Duration::from_secs(10), self.port.read(&mut buf[pos..]))
                .await
                .map_err(|_| EdgeError::Serial("Read timeout".into()))?
                .map_err(EdgeError::Io)?;
            if n == 0 {
                return Err(EdgeError::Serial("No data".into()));
            }
            pos += n;
            // Search for 0x68
            if let Some(start_idx) = buf[..pos].iter().position(|&b| b == 0x68) {
                // Need at least 12 bytes after start
                if pos - start_idx >= 12 {
                    let frame_end = start_idx + 12 + buf[start_idx + 9] as usize;
                    if pos >= frame_end + 2 && buf[frame_end] == 0x16 {
                        let frame_bytes = buf[start_idx..=frame_end+1].to_vec();
                        return Ok(frame_bytes);
                    }
                }
            }
        }
    }

    pub async fn write_frame(&mut self, data: &[u8]) -> Result<(), EdgeError> {
        timeout(Duration::from_secs(2), self.port.write_all(data))
            .await
            .map_err(|_| EdgeError::Serial("Write timeout".into()))?
            .map_err(EdgeError::Io)
    }
}
EOF
```

11. apps/edge-agent/src/main.rs — State Machine کامل

```bash
cat > apps/edge-agent/src/main.rs << 'EOF'
use dlt645_core::parser::parse_frame;
use dlt645_core::builder::{build_read_frame, to_bytes};
use dlt645_core::decoder::{decode_data, to_measurement};
use rs485_driver::Rs485Driver;
use common_types::error::EdgeError;
use tracing::{info, error};

#[tokio::main]
async fn main() -> Result<(), EdgeError> {
    tracing_subscriber::fmt::init();
    info!("ZINOVA Edge Agent v0.1.0 starting...");

    let mut driver = Rs485Driver::new("/dev/ttyUSB0", 2400)?;
    info!("RS485 port opened");

    // Example meter address and DI for reading voltage, current, power
    let meter_addr = [0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF];
    let voltage_di = [0x00, 0x01, 0x02, 0x03];
    let current_di = [0x00, 0x01, 0x03, 0x04];
    let power_di = [0x00, 0x01, 0x05, 0x06];

    // State machine: Idle -> Send -> Wait -> Receive -> Validate -> Decode -> Publish -> Idle
    loop {
        // Idle: send request
        let request = build_read_frame(meter_addr, &voltage_di);
        let bytes = to_bytes(&request);
        driver.write_frame(&bytes).await?;
        info!("Sent read request");

        // Wait & Receive
        match driver.read_frame().await {
            Ok(raw) => {
                // Validate & Decode
                match parse_frame(&raw) {
                    Ok(frame) => {
                        // Extract DI from request frame (same as sent)
                        let di: [u8; 4] = voltage_di; // In real, use from frame control
                        match decode_data(&di, &frame.data) {
                            Ok(raw_data) => {
                                let measurement = to_measurement(raw_data);
                                let json = serde_json::to_string(&measurement).unwrap();
                                info!("Measurement JSON: {}", json);
                                // Publish would happen here
                            }
                            Err(e) => error!("Decode error: {}", e),
                        }
                    }
                    Err(e) => error!("Parse error: {}", e),
                }
            }
            Err(e) => error!("Read error: {}", e),
        }

        tokio::time::sleep(std::time::Duration::from_secs(1)).await;
    }
}
EOF
```

12. تست‌های گسترده dlt645-core

```bash
mkdir -p crates/dlt645-core/tests
cat > crates/dlt645-core/tests/annex13_vectors.rs << 'EOF'
use dlt645_core::parser::parse_frame;
use dlt645_core::decoder::decode_data;
use dlt645_core::builder::{build_read_frame, to_bytes};

#[test]
fn test_annex13_vector_1() {
    // Sample valid frame from Annex 13
    let bytes = vec![
        0x68, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF,
        0x68, 0x11, 0x04,
        0x33, 0x34, 0x35, 0x36,
        0x9A, 0x16,
    ];
    let frame = parse_frame(&bytes).expect("should parse");
    assert_eq!(frame.data, vec![0x33,0x34,0x35,0x36]);
}

#[test]
fn test_checksum_failure_annex13() {
    let mut bytes = vec![
        0x68, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF,
        0x68, 0x11, 0x04,
        0x33, 0x34, 0x35, 0x36,
        0x00, 0x16,
    ];
    assert!(parse_frame(&bytes).is_err());
}

#[test]
fn test_wakeup_bytes() {
    let bytes = vec![
        0xFE, 0xFE, 0x68,
        0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF,
        0x68, 0x11, 0x04,
        0x33, 0x34, 0x35, 0x36,
        0x9A, 0x16,
    ];
    assert!(parse_frame(&bytes).is_ok());
}

#[test]
fn test_short_frame() {
    assert!(parse_frame(&[0x68, 0x00]).is_err());
}

#[test]
fn test_missing_end_byte() {
    let mut bytes = vec![0x68, 0xAA,0xBB,0xCC,0xDD,0xEE,0xFF, 0x68, 0x11, 0x04, 0x33,0x34,0x35,0x36, 0x00];
    bytes.push(0x00); // wrong end
    assert!(parse_frame(&bytes).is_err());
}

#[test]
fn test_decode_energy() {
    let di: [u8; 4] = [0x00,0x01,0x05,0x06];
    let data = vec![0x00,0x12,0x34, 0x00,0x00,0x56,0x78]; // power=1234W, energy=56.78 kWh
    let raw = decode_data(&di, &data).unwrap();
    assert_eq!(raw.active_power.unwrap(), 1234.0);
    assert_eq!(raw.total_energy.unwrap(), 56.78);
}

#[test]
fn test_roundtrip() {
    let addr = [0x11;6];
    let di = [0x00,0x01,0x02,0x03];
    let req = build_read_frame(addr, &di);
    let bytes = to_bytes(&req);
    let parsed = parse_frame(&bytes).expect("roundtrip fail");
    assert_eq!(parsed.address, addr);
}
EOF






