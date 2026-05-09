# WireGuard com Interface Web (WG-Easy)

## O que foi implantado

- Namespace `wireguard`
- Deployment `wg-easy`
- Service UDP na porta `51820` (VPN)
- Interface web exposta por HTTPRoute + DNSEndpoint

## Variáveis relevantes

- `wireguard_admin_password_hash`: hash bcrypt da senha da UI
- `wireguard_public_host`: host da UI (opcional, default `vpn.personaldevopstrainer.online`)

## Gerar hash bcrypt

Exemplo com Docker:

```bash
docker run --rm ghcr.io/wg-easy/wg-easy:15 wgpw 'SENHA_FORTE'
```

Use a saída no `wireguard_admin_password_hash`.

## Acesso

- UI: `https://vpn.personaldevopstrainer.online` (ou host custom)
- VPN: requer exposição UDP real de `51820` (Cloudflare Tunnel não encapsula WireGuard UDP)

## Exposição UDP

Como o service está `NodePort` por padrão:

1. Descobrir `nodePort`:
```bash
kubectl -n wireguard get svc wireguard-vpn -o wide
```
2. Criar NAT/port-forward no roteador para o NodePort/51820.
