# Nexus para artefatos Maven

## Acesso

- URL: `https://nexus.personaldevopstrainer.online`

## Repositórios recomendados

No Nexus, crie (via UI):

- `maven-releases` (hosted)
- `maven-snapshots` (hosted)

## Publicar artefatos via Maven

Opção 1: `distributionManagement` no `pom.xml` (recomendado para projetos reais)

- Configure os ids `nexus-releases` e `nexus-snapshots`
- Use credenciais via `~/.m2/settings.xml`

Opção 2: sem alterar `pom.xml`, usando `-DaltDeploymentRepository`

```bash
mvn -DskipTests deploy \
  -DaltDeploymentRepository=nexus::default::https://nexus.personaldevopstrainer.online/repository/maven-snapshots/
```

## Credenciais (sem commitar)

Crie `~/.m2/settings.xml` a partir do exemplo:

```xml
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 https://maven.apache.org/xsd/settings-1.0.0.xsd">
  <servers>
    <server>
      <id>nexus</id>
      <username>admin</username>
      <password>SUA_SENHA</password>
    </server>
    <server>
      <id>nexus-snapshots</id>
      <username>admin</username>
      <password>SUA_SENHA</password>
    </server>
    <server>
      <id>nexus-releases</id>
      <username>admin</username>
      <password>SUA_SENHA</password>
    </server>
  </servers>
</settings>
```

Depois, use `mvn deploy` normalmente.
