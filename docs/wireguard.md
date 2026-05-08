# WireGuard com Interface Web (WG-Easy)

## O que foi implantado

- Namespace `wireguard`
- Deployment `wg-easy`
- Service UDP na porta `51820` (VPN)
- Interface web exposta por HTTPRoute + DNSEndpoint

## Variaveis relevantes

- `wireguard_admin_password_hash`: hash bcrypt da senha da UI
- `wireguard_public_host`: host da UI (opcional, default `vpn.personaldevopstrainer.online`)

## Gerar hash bcrypt

Exemplo com Docker:

```bash
docker run --rm ghcr.io/wg-easy/wg-easy:15 wgpw 'SENHA_FORTE'
```

Use a saida no `wireguard_admin_password_hash`.

## Acesso

- UI: `https://vpn.personaldevopstrainer.online` (ou host custom)
- VPN: requer exposicao UDP real de `51820` (Cloudflare Tunnel nao encapsula WireGuard UDP)

## Exposicao UDP

Como o service esta `NodePort` por padrao:

1. Descobrir `nodePort`:
```bash
kubectl -n wireguard get svc wireguard-vpn -o wide
```
2. Criar NAT/port-forward no roteador para o NodePort/51820.
