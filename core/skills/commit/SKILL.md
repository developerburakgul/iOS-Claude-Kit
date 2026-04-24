---
name: commit
description: Conventional Commits v1.0.0 spesifikasyonuna göre commit oluşturur. Değişiklikleri analiz eder, uygun type ve scope belirler, commit mesajı önerir.
user-invocable: true
argument-hint: "mesaj"
---

# Conventional Commits v1.0.0

## Commit Formatı

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Kurallar

1. **type** zorunludur
2. **scope** opsiyoneldir, parantez içinde yazılır: `feat(auth): ...`
3. **description** zorunludur, type'dan sonra `: ` (iki nokta + boşluk) ile ayrılır
4. **description** küçük harfle başlar, sonunda nokta yok
5. **body** opsiyoneldir, description'dan bir boş satır sonra başlar
6. **footer** opsiyoneldir, body'den bir boş satır sonra başlar, `token: value` veya `token #value` formatında
7. **BREAKING CHANGE** belirtmek için: footer'a `BREAKING CHANGE: açıklama` yaz VEYA type'dan sonra `!` ekle: `feat!: ...`

---

## İzin Verilen Type'lar

| Type | Açıklama |
|---|---|
| `feat` | Yeni özellik (SemVer MINOR) |
| `fix` | Bug düzeltme (SemVer PATCH) |
| `docs` | Sadece dokümantasyon değişikliği |
| `style` | Kod davranışını etkilemeyen format değişiklikleri (boşluk, noktalama vb.) |
| `refactor` | Bug düzeltmeyen ve özellik eklemeyen kod değişikliği |
| `perf` | Performans iyileştirmesi |
| `test` | Test ekleme veya düzeltme |
| `build` | Build sistemi veya dış bağımlılık değişiklikleri (SPM, CocoaPods vb.) |
| `ci` | CI konfigürasyon dosyaları ve script'leri |
| `chore` | Kaynak kodu değiştirmeyen bakım işleri |
| `revert` | Önceki bir commit'i geri alma |

---

## Adımlar

Bu skill çağrıldığında şu adımları izle:

### 1. Değişiklikleri analiz et

```bash
git status
git diff --staged
git diff
```

- Eğer stage'lenmiş değişiklik varsa sadece onları commit et.
- Eğer stage'lenmiş değişiklik yoksa, unstaged değişiklikleri göster ve kullanıcıya hangi dosyaları stage'lemek istediğini sor.
- Eğer hiç değişiklik yoksa kullanıcıyı bilgilendir ve dur.

### 2. Commit mesajı oluştur

Değişiklikleri analiz edip uygun type'ı seç:

- **Yeni dosya/özellik eklendiyse** → `feat`
- **Bug düzeltildiyse** → `fix`
- **Sadece README/CLAUDE.md değiştiyse** → `docs`
- **Sadece test eklendiyse/değiştiyse** → `test`
- **Mevcut kod davranışı değişmeden yeniden yapılandırıldıysa** → `refactor`
- **Performans iyileştirmesiyse** → `perf`
- **Build/dependency değişikliğiyse** → `build`
- **Format/whitespace değişikliğiyse** → `style`
- **CI dosyaları değiştiyse** → `ci`
- **Diğer bakım işleriyse** → `chore`

**Scope belirleme (opsiyonel):**
- Değişiklik tek bir modül/feature'a aitse scope ekle: `feat(onboarding): ...`
- Birden fazla alanı kapsıyorsa scope kullanma: `feat: ...`

**Description yazımı:**
- İngilizce yaz
- Küçük harfle başla
- Emir kipi kullan ("add", "fix", "update" — "added", "fixed" değil)
- Sonunda nokta koyma
- Kısa ve net tut (50 karakter altı)

### 3. Son commit mesajlarıyla uyumu kontrol et

```bash
git log --oneline -10
```

Mevcut commit geçmişindeki dil ve stil ile tutarlı ol.

### 4. Kullanıcıya onayla ve commit et

Oluşturduğun commit mesajını kullanıcıya göster ve onayını al. Onay gelince:

```bash
git add <dosyalar>
git commit -m "<type>(<scope>): <description>"
```

Eğer body veya footer gerekiyorsa HEREDOC kullan:

```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <description>

<body>

<footer>
EOF
)"
```

---

## Örnekler

```
feat: add user authentication flow
fix(cart): resolve crash when removing last item
docs: update API integration guide
refactor(network): extract base request handler
feat!: drop iOS 16 support
test(payment): add RevenueCat purchase tests
build: update Firebase to 11.0
chore: remove unused asset catalogs

feat(auth): add biometric login support

Implements Face ID and Touch ID authentication
as an alternative to password-based login.

Closes #42

fix(sync)!: change data merge strategy

The previous merge strategy was causing data loss
when offline changes conflicted with server state.

BREAKING CHANGE: sync conflict resolution now
favors local changes over server changes
```

---

## Yapma

- Stage'lenmemiş dosyaları sormadan commit etme
- `git add .` veya `git add -A` kullanma — dosyaları tek tek ekle
- `.env`, credentials veya secret içeren dosyaları commit etme
- `--no-verify` kullanma
- `--amend` kullanma (kullanıcı açıkça istemediği sürece)
- Boş commit oluşturma
