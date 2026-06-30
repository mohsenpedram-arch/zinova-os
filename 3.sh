

1. crates/common-types/src/error.rs

```bash
cat > crates/common-types/src/error.rs << 'EOF'
use thiserror::Error;

#[derive(Error, Debug)]
pub enum EdgeError {
    #[error("DL/T645 error: {0}")]
    Dlt645(#[from] Dlt645Error),

    #[error("Serial error: {0}")]
    Serial(String),

    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Decode error: {0}")]
    Decode(String),

    #[error("Retry exhausted after {attempts} attempts")]
    RetryExhausted { attempts: u32 },
}

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

2. crates/common-types/src/types.rs

```bash
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
```

3. crates/dlt645-core/src/lib.rs

```bash
cat > crates/dlt645-core/src/lib.rs << 'EOF'
pub mod codec;
pub mod frame;
pub mod parser;
pub mod builder;
pub mod decoder;
pub mod error;
pub mod types;
pub mod profile;

pub use error::Dlt645Error;
pub use types::{Dlt645Frame, RawMeterData};
pub use profile::{MeterProfile, RegisterDef};
EOF
```

4. crates/dlt645-core/src/codec.rs — Offset Encoding/Decoding

```bash
cat > crates/dlt645-core/src/codec.rs << 'EOF'
/// Add 0x33 to each byte (used when sending)
pub fn encode_offset(data: &[u8]) -> Vec<u8> {
    data.iter().map(|b| b.wrapping_add(0x33)).collect()
}

/// Subtract 0x33 from each byte (used when receiving)
pub fn decode_offset(data: &[u8]) -> Vec<u8> {
    data.iter().map(|b| b.wrapping_sub(0x33)).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_roundtrip_offset() {
        let original = vec![0x12, 0x34, 0x56];
        let encoded = encode_offset(&original);
        let decoded = decode_offset(&encoded);
        assert_eq!(original, decoded);
    }
}
EOF
```

5. crates/dlt645-core/src/types.rs

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

6. crates/dlt645-core/src/profile.rs — Meter Profile Engine

```bash
cat > crates/dlt645-core/src/profile.rs << 'EOF'
use std::collections::HashMap;

#[derive(Debug, Clone)]
pub struct RegisterDef {
    pub unit: f32,
    pub format: DataFormat,
}

#[derive(Debug, Clone)]
pub enum DataFormat {
    Bcd,
    Integer,
}

#[derive(Debug, Clone)]
pub struct MeterProfile {
    pub registers: HashMap<[u8; 4], RegisterDef>,
}

impl MeterProfile {
    /// Example profile for a generic meter (some common DIs)
    pub fn default_profile() -> Self {
        let mut registers = HashMap::new();
        // Voltage A/B/C (DI 00010203) -> 2 bytes BCD, unit 0.1V
        registers.insert(
            [0x00, 0x01, 0x02, 0x03],
            RegisterDef { unit: 0.1, format: DataFormat::Bcd },
        );
        // Current A/B/C (DI 00010304) -> 2 bytes BCD, unit 0.01A
        registers.insert(
            [0x00, 0x01, 0x03, 0x04],
            RegisterDef { unit: 0.01, format: DataFormat::Bcd },
        );
        // Active power / total energy (DI 00010506) -> power 3B BCD 1W, energy 4B BCD 0.01kWh
        registers.insert(
            [0x00, 0x01, 0x05, 0x06],
            RegisterDef { unit: 1.0, format: DataFormat::Bcd }, // for power (part of it)
        );
        Self { registers }
    }

    pub fn get(&self, di: &[u8; 4]) -> Option<&RegisterDef> {
        self.registers.get(di)
    }
}
EOF
```

7. crates/dlt645-core/src/parser.rs (بدون تغییر عمده، فقط برای اطمینان)

```bash
cat > crates/dlt645-core/src/parser.rs << 'EOF'
use crate::error::Dlt645Error;
use crate::types::Dlt645Frame;

pub fn parse_frame(mut bytes: &[u8]) -> Result<Dlt645Frame, Dlt645Error> {
    // Strip leading wake-up bytes
    while bytes.first() == Some(&0xFE) {
        bytes = &bytes[1..];
    }
    if bytes.len() < 12 {
        return Err(Dlt645Error::FrameTooShort);
    }
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

fn compute_checksum(frame: &Dlt645Frame) -> u8 {
    let mut sum: u8 = 0;
    sum = sum.wrapping_add(0x68);
    for b in &frame.address { sum = sum.wrapping_add(*b); }
    sum = sum.wrapping_add(0x68);
    sum = sum.wrapping_add(frame.control);
    sum = sum.wrapping_add(frame.length);
    for b in &frame.data { sum = sum.wrapping_add(*b); }
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
EOF
```

8. crates/dlt645-core/src/builder.rs — با Offset در ارسال

```bash
cat > crates/dlt645-core/src/builder.rs << 'EOF'
use crate::types::Dlt645Frame;
use crate::codec::encode_offset;

pub fn build_read_frame(address: [u8; 6], data_identifier: &[u8]) -> Dlt645Frame {
    let control = 0x11;
    // Apply offset encoding to DI
    let encoded_di = encode_offset(data_identifier);
    let length = encoded_di.len() as u8;
    let data = encoded_di;
    let mut frame = Dlt645Frame {
        address,
        control,
        length,
        data,
        checksum: 0,
    };
    // Compute checksum (includes offset bytes)
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
EOF
```

9. crates/dlt645-core/src/decoder.rs — Offset و استخراج DI از پاسخ + MeterProfile

```bash
cat > crates/dlt645-core/src/decoder.rs << 'EOF'
use crate::error::Dlt645Error;
use crate::types::RawMeterData;
use crate::codec::decode_offset;
use crate::profile::MeterProfile;
use common_types::Measurement;

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

/// Decode response data using a MeterProfile.
/// `data` is the raw data field from the response frame (still offset-encoded).
/// Returns RawMeterData with decoded values according to the profile.
pub fn decode_response(
    profile: &MeterProfile,
    data: &[u8],
) -> Result<RawMeterData, Dlt645Error> {
    if data.len() < 4 {
        return Err(Dlt645Error::DecodeError("Response too short".to_string()));
    }
    // Extract DI (first 4 bytes), then data bytes after offset removal
    let di: [u8; 4] = data[0..4].try_into().unwrap();
    let payload = decode_offset(&data[4..]); // remove offset from actual data
    let reg = profile.get(&di).ok_or_else(|| {
        Dlt645Error::DecodeError(format!("Unknown DI {:02X?}", di))
    })?;
    let mut raw = RawMeterData::default();
    match di {
        [0x00, 0x01, 0x02, 0x03] => {
            if payload.len() >= 6 {
                raw.voltage_a = Some(bcd_to_u32(&payload[0..2])? as f32 * reg.unit);
                raw.voltage_b = Some(bcd_to_u32(&payload[2..4])? as f32 * reg.unit);
                raw.voltage_c = Some(bcd_to_u32(&payload[4..6])? as f32 * reg.unit);
            }
        }
        [0x00, 0x01, 0x03, 0x04] => {
            if payload.len() >= 6 {
                raw.current_a = Some(bcd_to_u32(&payload[0..2])? as f32 * reg.unit);
                raw.current_b = Some(bcd_to_u32(&payload[2..4])? as f32 * reg.unit);
                raw.current_c = Some(bcd_to_u32(&payload[4..6])? as f32 * reg.unit);
            }
        }
        [0x00, 0x01, 0x05, 0x06] => {
            if payload.len() >= 7 {
                raw.active_power = Some(bcd_to_u32(&payload[0..3])? as f32);
                raw.total_energy = Some(bcd_to_u32(&payload[3..7])? as f64 * 0.01);
            }
        }
        _ => {
            // Generic decode attempt
            if payload.len() >= 4 {
                raw.total_energy = Some(bcd_to_u32(&payload)? as f64 * 0.01);
            }
        }
    }
    Ok(raw)
}

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
        power_factor: None,
        frequency: Some(50.0),
        timestamp,
    }
}
EOF
```

10. crates/rs485-driver/src/lib.rs — Stream Reader مقاوم + Retry

```bash
cat > crates/rs485-driver/src/lib.rs << 'EOF'
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::time::{sleep, timeout, Duration};
use common_types::error::EdgeError;
use tracing::warn;

pub struct Rs485Driver {
    port: tokio_serial::SerialStream,
    retry_base_ms: u64,
    max_retries: u32,
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
        Ok(Self {
            port,
            retry_base_ms: 200,
            max_retries: 3,
        })
    }

    /// Stream-based frame reader with retry logic built-in.
    pub async fn read_frame_with_retry(&mut self) -> Result<Vec<u8>, EdgeError> {
        let mut attempt = 0;
        loop {
            match self.read_raw_frame().await {
                Ok(frame) => return Ok(frame),
                Err(e) if attempt < self.max_retries => {
                    attempt += 1;
                    let wait_ms = self.retry_base_ms * 2u64.pow(attempt);
                    warn!("Read error (attempt {}/{}), retrying in {}ms: {}", attempt, self.max_retries, wait_ms, e);
                    sleep(Duration::from_millis(wait_ms)).await;
                }
                Err(e) => return Err(EdgeError::RetryExhausted { attempts: attempt }),
            }
        }
    }

    async fn read_raw_frame(&mut self) -> Result<Vec<u8>, EdgeError> {
        let mut buf = vec![0u8; 512];
        let mut pos = 0;
        // read until we find a 0x68, then read enough for frame
        let start_found = loop {
            let n = timeout(Duration::from_secs(10), self.port.read(&mut buf[pos..]))
                .await
                .map_err(|_| EdgeError::Serial("Read timeout".into()))?
                .map_err(EdgeError::Io)?;
            if n == 0 {
                return Err(EdgeError::Serial("No data".into()));
            }
            pos += n;
            if let Some(start) = buf[..pos].iter().position(|&b| b == 0x68) {
                break start;
            }
        };
        let start = start_found;
        // We need at least 12 bytes from start to read length
        while pos - start < 12 {
            let n = timeout(Duration::from_secs(1), self.port.read(&mut buf[pos..]))
                .await
                .map_err(|_| EdgeError::Serial("Timeout reading header".into()))?
                .map_err(EdgeError::Io)?;
            if n == 0 {
                return Err(EdgeError::Serial("Connection closed during header".into()));
            }
            pos += n;
        }
        let length = buf[start + 9] as usize;
        let total_needed = start + 12 + length + 1; // +1 for end byte 0x16
        while pos < total_needed {
            let n = timeout(Duration::from_secs(2), self.port.read(&mut buf[pos..]))
                .await
                .map_err(|_| EdgeError::Serial("Timeout reading frame body".into()))?
                .map_err(EdgeError::Io)?;
            if n == 0 {
                return Err(EdgeError::Serial("Connection closed mid-frame".into()));
            }
            pos += n;
        }
        if buf[total_needed - 1] != 0x16 {
            return Err(EdgeError::Serial("Frame end byte missing".into()));
        }
        Ok(buf[start..total_needed].to_vec())
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

11. apps/edge-agent/src/main.rs — حلقه کامل با Retry و پروفایل

```bash
cat > apps/edge-agent/src/main.rs << 'EOF'
use dlt645_core::parser::parse_frame;
use dlt645_core::builder::{build_read_frame, to_bytes};
use dlt645_core::decoder::{decode_response, to_measurement};
use dlt645_core::profile::MeterProfile;
use rs485_driver::Rs485Driver;
use common_types::error::EdgeError;
use tracing::{info, error};

#[tokio::main]
async fn main() -> Result<(), EdgeError> {
    tracing_subscriber::fmt::init();
    info!("ZINOVA Edge Agent v0.1.0 starting...");

    let mut driver = Rs485Driver::new("/dev/ttyUSB0", 2400)?;
    info!("RS485 port opened");

    let profile = MeterProfile::default_profile();
    let meter_addr = [0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF];
    let dis = vec![
        [0x00, 0x01, 0x02, 0x03],
        [0x00, 0x01, 0x03, 0x04],
        [0x00, 0x01, 0x05, 0x06],
    ];

    // State machine loop
    for di in dis.iter() {
        // Send request
        let request = build_read_frame(meter_addr, di);
        let bytes = to_bytes(&request);
        driver.write_frame(&bytes).await?;
        info!("Sent read request for DI {:02X?}", di);

        // Receive with retry
        match driver.read_frame_with_retry().await {
            Ok(raw) => {
                match parse_frame(&raw) {
                    Ok(frame) => {
                        match decode_response(&profile, &frame.data) {
                            Ok(raw_data) => {
                                let measurement = to_measurement(raw_data);
                                let json = serde_json::to_string(&measurement).unwrap();
                                info!("Measurement: {}", json);
                            }
                            Err(e) => error!("Decode error: {}", e),
                        }
                    }
                    Err(e) => error!("Parse error: {}", e),
                }
            }
            Err(e) => error!("Read failed: {}", e),
        }

        tokio::time::sleep(std::time::Duration::from_millis(500)).await;
    }

    Ok(())
}
EOF
```

12. تست‌های گسترده و فاز (Fuzz, Noise)

```bash
cat > crates/dlt645-core/tests/robustness.rs << 'EOF'
use dlt645_core::parser::parse_frame;
use dlt645_core::builder::{build_read_frame, to_bytes};
use dlt645_core::codec::{encode_offset, decode_offset};
use dlt645_core::profile::MeterProfile;
use dlt645_core::decoder::decode_response;

#[test]
fn test_offset_roundtrip_in_frame() {
    let addr = [0xAA;6];
    let di = [0x01,0x02,0x03,0x04];
    let request = build_read_frame(addr, &di);
    let bytes = to_bytes(&request);
    let parsed = parse_frame(&bytes).expect("valid");
    // data field should be offset-encoded DI
    assert_eq!(parsed.data, encode_offset(&di));
}

#[test]
fn test_decode_with_profile() {
    let profile = MeterProfile::default_profile();
    // Build a response for DI 00010203 with voltage values
    let raw_data = vec![0x22, 0x00, 0x22, 0x10, 0x21, 0x99]; // after offset removal -> 220.0, 221.0, 219.9
    let di = [0x00, 0x01, 0x02, 0x03];
    let mut response_data = di.to_vec();
    response_data.extend(encode_offset(&raw_data)); // apply offset
    let result = decode_response(&profile, &response_data).unwrap();
    assert!((result.voltage_a.unwrap() - 220.0).abs() < 0.01);
    assert!((result.voltage_c.unwrap() - 219.9).abs() < 0.01);
}

#[test]
fn test_noise_injection() {
    let valid = vec![
        0x68, 0xAA,0xBB,0xCC,0xDD,0xEE,0xFF,
        0x68, 0x11, 0x04,
        0x33,0x34,0x35,0x36,
        0x9A, 0x16,
    ];
    let mut noisy = vec![0xFF, 0x00, 0x01, 0x68];
    noisy.extend(&valid[1..]);
    let parsed = parse_frame(&noisy);
    assert!(parsed.is_err()); // because start byte not 0x68 at index 0
}

#[test]
fn test_multiple_frames() {
    let frame1 = vec![
        0xFE, 0x68, 0xAA,0xAA,0xAA,0xAA,0xAA,0xAA, 0x68, 0x11, 0x04,
        0x33,0x34,0x35,0x36, 0x9A, 0x16,
    ];
    let frame2 = vec![
        0x68, 0xBB,0xBB,0xBB,0xBB,0xBB,0xBB, 0x68, 0x11, 0x04,
        0x43,0x44,0x45,0x46, 0xAA, 0x16,
    ];
    let combined = [frame1, frame2].concat();
    // Parser should handle first complete frame
    let result = parse_frame(&combined);
    assert!(result.is_ok());
}

#[test]
fn test_short_noise() {
    assert!(parse_frame(&[0x68, 0x00, 0x01]).is_err());
}
EOF
```

13. Benchmark (پایه)

```bash
mkdir -p benches
cat > benches/parse_benchmark.rs << 'EOF'
use criterion::{black_box, Criterion};
use dlt645_core::parser::parse_frame;
use dlt645_core::builder::{build_read_frame, to_bytes};

pub fn bench_parse(c: &mut Criterion) {
    let addr = [0xAA;6];
    let di = [0x00,0x01,0x02,0x03];
    let frame = build_read_frame(addr, &di);
    let bytes = to_bytes(&frame);
    c.bench_function("parse_frame", |b| {
        b.iter(|| parse_frame(black_box(&bytes)))
    });
}

criterion::criterion_group!(benches, bench_parse);
criterion::criterion_main!(benches);
EOF


