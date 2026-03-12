# install/ — BOM 디렉토리

## bom.json

phoneparis baptism 원장. `install.sh` 실행 시 자동 갱신됨.

| 필드 | 설명 |
|------|------|
| `_meta.canonical` | `true` = Termux(원장 기준) 실행 결과 |
| `_meta.generated` | 실행 시각 |
| `system` | 시스템 패키지 (pkg/apt/brew) |
| `python` | pip 패키지 |
| `npm` | npm 패키지 |
| `blocked` | 설치 불가 — 대안 명시 |

## phoneparis 동기화

Termux에서 `install.sh` 실행 후:

```bash
cp install/bom.json ../phoneparis/tools/baptism/config/packages.json
```

`canonical: true` 인 BOM만 원장으로 사용할 것.
