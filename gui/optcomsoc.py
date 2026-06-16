#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Panel de bienvenida OptiComSoc.
Abre una ventana que da la bienvenida y permite lanzar cada servicio
de la red corporativa en el navegador. Funciona para el Nodo A y el B.

Uso:  python3 optcomsoc.py
Requiere: python3-tk  (sudo apt install -y python3-tk)
"""
import webbrowser
import tkinter as tk

from servicios import NODOS, SERVICIOS, build_url

# ----- Paleta -----
BG       = "#0f1b2d"   # fondo general (azul muy oscuro)
HEADER   = "#13294b"   # barra superior
CARD_BG  = "#1c2c44"   # tarjetas
CARD_HOV = "#26395a"   # tarjeta al pasar el mouse
TEXT     = "#eaf0fa"
SUBTEXT  = "#9fb3d1"
ACCENT   = "#13bef9"

estado = {"nodo": "A"}   # nodo seleccionado actualmente


def abrir(servicio):
    url = build_url(servicio, estado["nodo"])
    webbrowser.open_new_tab(url)


def construir():
    root = tk.Tk()
    root.title("OptiComSoc")
    root.configure(bg=BG)
    root.geometry("780x640")
    root.minsize(680, 560)

    # ---------------- Encabezado ----------------
    header = tk.Frame(root, bg=HEADER)
    header.pack(fill="x")

    tk.Label(header, text="OptiComSoc", bg=HEADER, fg=ACCENT,
             font=("DejaVu Sans", 26, "bold")).pack(anchor="w", padx=24, pady=(18, 0))
    tk.Label(header, text="Red Corporativa de Alta Disponibilidad",
             bg=HEADER, fg=SUBTEXT, font=("DejaVu Sans", 11)).pack(anchor="w", padx=24, pady=(0, 16))

    tk.Label(root, text="Bienvenido a OptiComSoc", bg=BG, fg=TEXT,
             font=("DejaVu Sans", 18, "bold")).pack(anchor="w", padx=24, pady=(18, 2))
    tk.Label(root, text="Elige un servicio para abrirlo en el navegador.",
             bg=BG, fg=SUBTEXT, font=("DejaVu Sans", 11)).pack(anchor="w", padx=24)

    # ---------------- Selector de nodo ----------------
    selector = tk.Frame(root, bg=BG)
    selector.pack(anchor="w", padx=24, pady=14)

    pie_var = tk.StringVar(value=NODOS["A"]["nombre"])
    botones_nodo = {}

    def seleccionar_nodo(key):
        estado["nodo"] = key
        pie_var.set(f"Destino actual:  {NODOS[key]['nombre']}  ({NODOS[key]['ip']})")
        for k, b in botones_nodo.items():
            if k == key:
                b.configure(bg=ACCENT, fg="#06243b")
            else:
                b.configure(bg=CARD_BG, fg=TEXT)

    for key in ("A", "B"):
        b = tk.Button(selector, text=NODOS[key]["nombre"], font=("DejaVu Sans", 10, "bold"),
                      bd=0, padx=16, pady=8, cursor="hand2",
                      activebackground=ACCENT, command=lambda k=key: seleccionar_nodo(k))
        b.pack(side="left", padx=(0, 10))
        botones_nodo[key] = b

    # ---------------- Tarjetas de servicios ----------------
    grid = tk.Frame(root, bg=BG)
    grid.pack(fill="both", expand=True, padx=20, pady=(4, 8))
    for c in range(2):
        grid.columnconfigure(c, weight=1, uniform="col")

    def crear_tarjeta(parent, servicio, fila, col):
        card = tk.Frame(parent, bg=CARD_BG, cursor="hand2", highlightthickness=0)
        card.grid(row=fila, column=col, sticky="nsew", padx=8, pady=8, ipady=6)

        franja = tk.Frame(card, bg=servicio["color"], width=6)
        franja.pack(side="left", fill="y")

        cuerpo = tk.Frame(card, bg=CARD_BG)
        cuerpo.pack(side="left", fill="both", expand=True, padx=14, pady=12)

        tk.Label(cuerpo, text=servicio["nombre"], bg=CARD_BG, fg=TEXT,
                 font=("DejaVu Sans", 13, "bold"), anchor="w").pack(fill="x")
        tk.Label(cuerpo, text=servicio["desc"], bg=CARD_BG, fg=SUBTEXT,
                 font=("DejaVu Sans", 10), anchor="w").pack(fill="x", pady=(2, 0))
        tk.Label(cuerpo, text="Abrir  ↗", bg=CARD_BG, fg=servicio["color"],
                 font=("DejaVu Sans", 10, "bold"), anchor="w").pack(fill="x", pady=(8, 0))

        widgets = [card, cuerpo] + list(cuerpo.winfo_children())

        def on_enter(_e):
            for w in [card, cuerpo] + list(cuerpo.winfo_children()):
                if w is not franja:
                    w.configure(bg=CARD_HOV)
        def on_leave(_e):
            for w in [card, cuerpo] + list(cuerpo.winfo_children()):
                if w is not franja:
                    w.configure(bg=CARD_BG)
        def on_click(_e, s=servicio):
            abrir(s)

        for w in widgets:
            w.bind("<Enter>", on_enter)
            w.bind("<Leave>", on_leave)
            w.bind("<Button-1>", on_click)

    for i, servicio in enumerate(SERVICIOS):
        crear_tarjeta(grid, servicio, i // 2, i % 2)

    # ---------------- Pie ----------------
    pie = tk.Label(root, textvariable=pie_var, bg=BG, fg=SUBTEXT,
                   font=("DejaVu Sans", 10), anchor="w")
    pie.pack(fill="x", padx=24, pady=(0, 14))

    seleccionar_nodo("A")  # estado inicial
    root.mainloop()


if __name__ == "__main__":
    construir()
