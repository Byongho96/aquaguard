# 🐠 Fish API - Frontend/rasp Guide

## 1️⃣ HTTP REST API 예시

### 센서 데이터 수집 (라즈베리파이 → Backend)
```bash
POST /api/v1/sensor/ingest
Content-Type: application/json

{
  "tankId": "1",
  "temperature": 25.5,
  "do": 7.2,
  "salt": 8.1,
  "ntu": 2.5
}

응답:
{
  "id": 1,
  "tankId": "1",
  "status": "ok"
}
```

---

## 2️⃣ 수조 목록 조회 (GET)

### 모든 수조와 센서 제어 상태 조회
```bash
GET /tanks
Content-Type: application/json

응답:
{
  "tanks": [
    {
      "tankId": "1",
      "sensors": [
        {
          "sensorId": "temperature",
          "state": true
        },
        {
          "sensorId": "do",
          "state": false
        },
        {
          "sensorId": "salt",
          "state": false
        },
        {
          "sensorId": "ntu",
          "state": false
        }
      ]
    },
    {
      "tankId": "2",
      "sensors": [...]
    }
  ]
}
```

### 실시간 센서 데이터 (최신 1개)
```bash
GET /tanks/{tankId}/realtime
예: GET /tanks/1/realtime

응답:
{
  "temperature": 25.5,
  "do": 7.2,
  "salt": 8.1,
  "ntu": 2.5
}
```

### 과거 센서 데이터 (최근 5개)
```bash
GET /tanks/{tankId}/history
예: GET /tanks/1/history

응답:
{
  "temperature": [22.1, 23.5, 24.2, 25.0, 25.5],
  "do": [6.8, 7.0, 7.1, 7.1, 7.2],
  "salt": [8.0, 8.0, 8.05, 8.08, 8.1],
  "ntu": [2.2, 2.3, 2.4, 2.5, 2.5]
}
```

---

## 3️⃣ 센서 제어 (Control) API

### 제어 상태 조회
```bash
GET /tanks/{tankId}/{sensorId}/control
예: GET /tanks/1/temperature/control

응답:
{
  "state": true
}
```

### 제어 상태 업데이트
```bash
POST /tanks/{tankId}/{sensorId}/control
예: POST /tanks/1/temperature/control
Content-Type: application/json

{
  "state": true
}

응답:
{
  "state": true
}
```

### PUT도 동일 (동작 동일):
```bash
PUT /tanks/{tankId}/{sensorId}/control
예: PUT /tanks/1/temperature/control
Content-Type: application/json

{
  "state": true
}
```

---

## 4️⃣ 센서 범위 (Range) API

### 범위 조회
```bash
GET /tanks/{tankId}/{sensorId}/range
예: GET /tanks/1/temperature/range

응답:
{
  "min": 20.0,
  "max": 30.0
}
```

### 범위 설정
```bash
POST /tanks/{tankId}/{sensorId}/range
예: POST /tanks/1/temperature/range
Content-Type: application/json

{
  "min": 20.0,
  "max": 30.0
}

응답:
{
  "min": 20.0,
  "max": 30.0
}
```

---

## 5️⃣ AI 활성화 API

### AI 상태 조회
```bash
GET /tanks/{tankId}/aienable
예: GET /tanks/1/aienable

응답:
{
  "state": false
}
```

### AI 활성화/비활성화
```bash
POST /tanks/{tankId}/aienable
예: POST /tanks/1/aienable
Content-Type: application/json

{
  "state": true
}

응답:
{
  "state": true
}
```

---

## 6️⃣ WebSocket 구독 및 메시지

### 1. 실시간 센서 데이터 (수신)
```javascript
// 구독
stompClient.subscribe('/topic/tanks/1/realtime', (message) => {
    const data = JSON.parse(message.body);
    console.log('실시간 데이터:', data);
});

// 수신 형식:
{
  "temperature": 25.5,
  "do": 7.2,
  "salt": 8.1,
  "ntu": 2.5
}
```

### 2. 센서 제어 상태 변경 (수신)
```javascript
// 구독
stompClient.subscribe('/topic/tanks/1/temperature/sensorenable', (message) => {
    const data = JSON.parse(message.body);
    console.log('제어 상태 변경:', data);
});

// 수신 형식:
{
  "state": true
}
```

### 3. 센서 범위 설정 변경 (수신)
```javascript
// 구독
stompClient.subscribe('/topic/tanks/1/temperature/sensorrange', (message) => {
    const data = JSON.parse(message.body);
    console.log('범위 설정 변경:', data);
});

// 수신 형식:
{
  "min": 20.0,
  "max": 30.0
}
```

### 4. AI 활성화 상태 변경 (수신)
```javascript
// 구독
stompClient.subscribe('/topic/tanks/1/aienable', (message) => {
    const data = JSON.parse(message.body);
    console.log('AI 상태 변경:', data);
});

// 수신 형식:
{
  "state": true
}
```

### 5. GPS 송신
```javascript
function sendGpsData(truckId, latitude, altitude) {
    const payload = {
        truckId: truckId,
        latitude: latitude,
        altitude: altitude
    };

    stompClient.send("/topic/trucks/gps", {}, JSON.stringify(payload));
}
```

### 6. GPS 수신
```javascript
// 구독
stompClient.subscribe('/topic/trucks/gps', (message) => {
    const data = JSON.parse(message.body);
    console.log('GPS 수신:', data);
});

// 수신 형식:
{
  "truckId" : 1,
  "latitude" : 48.2,
  "altitude" : 42.2,
}
```
