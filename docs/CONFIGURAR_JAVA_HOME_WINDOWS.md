# Tutorial: Configurar JAVA_HOME no Windows

Este tutorial resolve o crash do daemon do Gradle que estava usando JDK 21 (incompatível). Vamos instalar JDK 17 e configurar JAVA_HOME.

## Problema Identificado
- Gradle daemon estava crashando com JVM usando Java 21 (JBR do Android Studio)
- Erro no log: `EXCEPTION_ACCESS_VIOLATION` em `hs_err_pid9804.log`
- Solução: Usar JDK 17 estável em vez do JBR 21

## Passo 1: Baixar e Instalar JDK 17

### Opção A: Oracle JDK 17 (gratuito para desenvolvimento)
1. Acesse: https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html
2. Baixe: **Windows x64 Installer** (.exe) - mais fácil de instalar
3. Execute o instalador como Administrador
4. Instale no caminho padrão: `C:\Program Files\Java\jdk-17.0.12`

### Opção B: Eclipse Temurin 17 (alternativa open-source)
1. Acesse: https://adoptium.net/temurin/releases/?version=17
2. Baixe: **Windows x64 JDK .msi** 
3. Execute o instalador como Administrador
4. Instale no caminho padrão: `C:\Program Files\Eclipse Adoptium\jdk-17.0.x-hotspot`

## Passo 2: Verificar a Instalação

Abra PowerShell e verifique se o JDK foi instalado:

```powershell
# Verificar se o diretório existe
dir "C:\Program Files\Java"
# ou para Eclipse Temurin:
dir "C:\Program Files\Eclipse Adoptium"
```

Anote o caminho exato do JDK instalado (ex: `C:\Program Files\Java\jdk-17.0.12`).

## Passo 3: Configurar JAVA_HOME (Método GUI - Recomendado)

### Windows 10/11:
1. **Pressione** `Win + R`, digite `sysdm.cpl` e pressione Enter
2. **Clique** na aba "Avançado"
3. **Clique** em "Variáveis de Ambiente"
4. **Em "Variáveis do Sistema" (seção inferior):**
   - Clique em "Novo"
   - Nome da variável: `JAVA_HOME`
   - Valor da variável: `C:\Program Files\Java\jdk-17.0.12` (ajuste conforme sua instalação)
   - Clique "OK"

5. **Atualizar PATH:**
   - Na lista "Variáveis do Sistema", encontre "Path" e clique "Editar"
   - Clique "Novo"
   - Digite: `%JAVA_HOME%\bin`
   - Clique "OK" em todas as janelas

### Alternativa via Settings (Windows 10/11):
1. **Configurações** → **Sistema** → **Sobre** → **Configurações Avançadas do Sistema**
2. **Variáveis de Ambiente** → **Nova** (em Variáveis do Sistema)
3. Nome: `JAVA_HOME`, Valor: caminho do JDK
4. Editar "Path" → Adicionar `%JAVA_HOME%\bin`

## Passo 4: Configurar JAVA_HOME (Método PowerShell)

**IMPORTANTE**: Execute PowerShell como Administrador para alterar variáveis do sistema.

```powershell
# Definir JAVA_HOME (ajuste o caminho conforme sua instalação)
setx JAVA_HOME "C:\Program Files\Java\jdk-17.0.12" /M

# Adicionar ao PATH do sistema (só se não existir)
$javaPath = "$env:JAVA_HOME\bin"
$machinePath = [Environment]::GetEnvironmentVariable('Path','Machine')

if (-not $machinePath.Contains($javaPath)) {
    $newPath = "$javaPath;" + $machinePath
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'Machine')
    Write-Host "PATH atualizado com JAVA_HOME\bin"
} else {
    Write-Host "PATH já contém JAVA_HOME\bin"
}
```

## Passo 5: Verificar a Configuração

**Importante**: Feche e reabra o PowerShell/IDE após configurar as variáveis.

```powershell
# Verificar se JAVA_HOME está definido
echo $env:JAVA_HOME

# Verificar versão do Java
java -version

# Verificar javac (compilador)
javac -version
```

**Saída esperada**:
```
openjdk version "17.0.12" 2024-07-16
OpenJDK Runtime Environment (build 17.0.12+7-Ubuntu-1ubuntu2)
OpenJDK 64-Bit Server VM (build 17.0.12+7-Ubuntu-1ubuntu2, mixed mode)
```

## Passo 6: Testar o Build do Flutter

```powershell
# Navegar para o projeto
cd 'c:\projetos\app moveis\ponto_digital_app'

# Limpar cache
flutter clean

# Baixar dependências
flutter pub get

# Rodar no emulador
flutter run -d emulator-5554
```

## Solução de Problemas

### Se ainda der erro de Gradle:
```powershell
# Verificar se emulador está rodando
flutter devices

# Build com mais detalhes
cd 'c:\projetos\app moveis\ponto_digital_app\android'
.\gradlew assembleDebug --stacktrace --info
```

### Se JAVA_HOME não for reconhecido:
1. **Reinicie** completamente a máquina
2. **Verifique** se o caminho do JDK está correto
3. **Use** aspas no PowerShell: `"C:\Program Files\Java\jdk-17.0.12"`

### Verificar múltiplas versões Java:
```powershell
# Ver todas as instalações Java
where java
where javac

# Ver versões instaladas
dir "C:\Program Files\Java"
dir "C:\Program Files\Eclipse Adoptium"
```

## Dicas Importantes

1. **Sempre** use o **caminho completo** sem espaços desnecessários
2. **Reinicie** IDE e terminais após alterar variáveis de ambiente
3. **Use** PowerShell como **Administrador** para alterar variáveis do sistema
4. **Teste** com `java -version` antes de prosseguir
5. Se tiver múltiplas versões Java, **JAVA_HOME** determina qual será usada

## Próximos Passos

Após configurar JAVA_HOME com sucesso:

1. ✅ **Testar**: `java -version` deve mostrar JDK 17
2. ✅ **Limpar**: `flutter clean` 
3. ✅ **Executar**: `flutter run -d emulator-5554`
4. ✅ **Validar**: App deve abrir no emulador sem crashes do Gradle

Se o problema persistir, pode ser necessário:
- Configurar `org.gradle.java.home` diretamente no `android/gradle.properties`
- Atualizar a versão do Gradle ou Android Gradle Plugin
- Verificar logs adicionais com `--stacktrace`

---

**Última atualização**: 26 de setembro de 2025  
**Contexto**: Corrigindo crash do Gradle daemon (JDK 21 → JDK 17)