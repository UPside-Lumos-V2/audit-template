# Audit Template

DeFi 해킹 사건 분석을 위한 협업 템플릿. GitHub IssueOps 기반 자동화와 실행 기반 피처 수집을 지원한다.

## 방법론

### 데이터 수집 원칙

1. 정성적 평가 배제 - 주관적 점수(severity 1-10 등) 사용하지 않음
2. 실행 기반 검증 - 시뮬레이션에서 자동으로 수집 가능한 데이터만 활용
3. 희소 데이터 - Dune 등 기존 분석 플랫폼에 없는 storage 접근 패턴 등 수집

### 피처 분류

| 구분 | 수집 방식 | 예시 |
|------|----------|------|
| Labeled | 오디터가 enum 선택 | VulnerabilityType |
| Derived | 실행 시 자동 | gas, profit, storage reads/writes |

### 오디터 작업

```solidity
function testExploit() public exploit(VulnerabilityType.REENTRANCY) {
    // PoC 구현
}
```

enum 하나만 선택하면 나머지는 `exploit` modifier가 자동 수집한다.

## 자동화

### Issue 생성

GitHub Issue Template으로 incident를 등록하면 다음이 자동 실행된다.

1. Infura RPC로 tx 메타데이터 조회 (block, timestamp, attacker, target)
2. 브랜치 생성 및 워크스페이스 초기화
3. Replay 테스트 검증
4. 오디터 자동 assign

### 생성되는 파일

```
test/2024-02-28_Seneca/
├── SenecaBase.sol      # 공유 Base
├── Replay.t.sol        # 원본 tx 재현
├── PoC_alice.t.sol     # 오디터별 PoC
├── PoC_bob.t.sol
└── README.md
```

### 출력 데이터

`forge test` 실행 시 `data/results/`에 JSON 생성:

```json
{
  "vulnerability_type": 1,
  "gas_used": 234567,
  "profit_wei": 1000000000000000000,
  "storage_reads_count": 15,
  "storage_writes_count": 3,
  "target": "0x..."
}
```

## 요구사항

- [Foundry](https://github.com/foundry-rs/foundry)
- GitHub Actions secrets: `INFURA_API_KEY`
