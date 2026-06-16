# -*- coding: utf-8 -*-
"""Definición de nodos y servicios de la red OptiComSoc.
Lógica pura (sin interfaz) para poder probarla por separado."""

NODOS = {
    "A": {"nombre": "Nodo A  ·  empresa.ComSoc",  "ip": "10.0.0.10", "dominio": "empresa.ComSoc"},
    "B": {"nombre": "Nodo B  ·  empresa.Opticom", "ip": "10.0.0.20", "dominio": "empresa.Opticom"},
}

SERVICIOS = [
    {"id": "portainer",  "nombre": "Portainer",            "desc": "Gestión de contenedores",      "color": "#13bef9",
     "url": lambda ip, dom: f"https://{ip}:9443"},
    {"id": "pihole",     "nombre": "Pi-hole (DNS)",        "desc": "Servidor de nombres local",    "color": "#a0132f",
     "url": lambda ip, dom: f"http://{ip}:8053/admin"},
    {"id": "npm",        "nombre": "Nginx Proxy Manager",  "desc": "Proxy inverso / subdominios",  "color": "#f15a2b",
     "url": lambda ip, dom: f"http://{ip}:81"},
    {"id": "phpmyadmin", "nombre": "phpMyAdmin",           "desc": "Base de datos (réplica)",      "color": "#6c78af",
     "url": lambda ip, dom: f"http://db.{dom}"},
    {"id": "correo",     "nombre": "Correo / Webmail",     "desc": "Buzón corporativo",            "color": "#2e8b57",
     "url": lambda ip, dom: f"http://correo.{dom}"},
    {"id": "voip",       "nombre": "Central VoIP",         "desc": "FreePBX · telefonía",          "color": "#e67e22",
     "url": lambda ip, dom: f"http://pbx.{dom}"},
    {"id": "syncthing",  "nombre": "Syncthing",            "desc": "Sincronización de archivos",   "color": "#0891d1",
     "url": lambda ip, dom: f"http://{ip}:8384"},
]

def build_url(servicio, nodo_key):
    n = NODOS[nodo_key]
    return servicio["url"](n["ip"], n["dominio"])
