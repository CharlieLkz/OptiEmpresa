# VoIP — FreePBX: extensiones y marcación por nombre

## 1. Entrar a FreePBX
Tras `docker compose up -d`, espera 3–5 min (instala Asterisk).
Accede por NPM: `http://pbx.empresa.ComSoc`
(o directo por IP si aún no configuras el proxy: `http://10.0.0.10`).
La primera vez te pide crear el usuario admin del panel.

## 2. Crear las 5 extensiones
**Applications → Extensions → Add Extension → Chan PJSIP**

| Display Name | User Extension | Secret (password) |
|--------------|----------------|-------------------|
| Charlie      | 1001           | Char.1001         |
| Emir         | 1002           | Emir.1002         |
| Dibri        | 1003           | Dibr.1003         |
| Diego        | 1004           | Dieg.1004         |
| Luis         | 1005           | Luis.1005         |

> El campo **Display Name** es lo que habilita la marcación por nombre.
Tras cada cambio pulsa el botón rojo **Apply Config** (arriba a la derecha).

## 3. Marcación por NOMBRE (alias) además del número
FreePBX trae el módulo **Directory** (Dial by Name), pero lo más
rápido y a prueba de balas para la demo es un dialplan personalizado.

**Admin → Config Edit → extensions_custom.conf** y agrega:

```
[from-internal-custom]
; Marcar por alias -> redirige a la extensión numérica
exten => charlie,1,Goto(from-internal,1001,1)
exten => emir,1,Goto(from-internal,1002,1)
exten => dibri,1,Goto(from-internal,1003,1)
exten => diego,1,Goto(from-internal,1004,1)
exten => luis,1,Goto(from-internal,1005,1)
```

En clientes SIP que permiten marcar texto (Linphone acepta letras),
marca `charlie` y sonará la extensión 1001. Quien no acepte letras,
marca el número `1001` normalmente. **Apply Config**.

## 4. Configurar los clientes SIP (Linphone / Zoiper)
En cada laptop/celular de la subred:

- **Servidor / Domain / SIP Proxy:** `10.0.0.10` (Nodo A) o `pbx.empresa.ComSoc`
- **Usuario / Username:** el número de extensión (ej. `1001`)
- **Contraseña:** el Secret de esa extensión (ej. `Char.1001`)
- **Transporte:** UDP, puerto **5060**

Repite apuntando a `10.0.0.20` para registrar contra el **Nodo B**
(centralita espejo) en caso de caída del Nodo A.

## 5. Prueba
Registra dos softphones (1001 y 1002), marca `1002` desde el 1001:
debe timbrar y establecer audio bidireccional (RTP 18000–18100/udp).
