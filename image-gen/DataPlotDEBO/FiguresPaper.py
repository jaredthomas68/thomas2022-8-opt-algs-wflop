from turtle import circle
import numpy as np
# import plotly.graph_objects as go
import matplotlib.pyplot as plt
import matplotlib.patches as patches
import pickle
import os

# load greedy data
ngreed = 33

path = "./"
n = 33
file_name_greed = os.path.join(path, "greedy_initialization_" + str(n) + ".pickle")

with open(file_name_greed, "rb") as fh:
    dict_greed = pickle.load(fh)


Xturb = dict_greed["layout"]
pot_loc = dict_greed["potential_locations"]
polys = dict_greed["poly"]

# plotly code for greedy
# fig = go.Figure()
# fig.add_trace(go.Scatter(x=Xturb[0, :], y=Xturb[1, :], name="Turbines location", mode="markers",
#                          marker=dict(size=12, color="#85C0F9")))
# fig.add_trace(go.Scatter(x=pot_loc[0, :], y=pot_loc[1, :], name="Potential locations", mode="markers",
#                                  marker=dict(size=6, color="#F5793A")))
# for n_poly, poly in enumerate(polys):
#     x, y = poly["x"], poly["y"]
#     fig.add_trace(
#         go.Scatter(x=x, y=y, name="Boundary " + str(n_poly), mode="lines", line=dict(color="black")))
# fig.update_layout(
#     yaxis=dict(
#         scaleanchor="x",
#         scaleratio=1,
#     ),
#     template="simple_white"
# )
# fig.show()

# pyplot code
turbine_radius = 99.0
fig, ax = plt.subplots(1,2, figsize=(8,4))
colors = ["#BDB8AD", "#85C0F9", "#0F2080", "#F5793A", "#A95AA1", "#382119"]
turbine_color = colors[2]
boundary_color = colors[0]
pot_loc_color = colors[3]

# add boundaries
for n_poly, poly in enumerate(polys):
    x, y = poly["x"], poly["y"]
    ax[0].plot(x, y, color=boundary_color, zorder=0)

# add turbines
for i in np.arange(0, len(Xturb[0,:])):
    c = patches.Circle((Xturb[0, i], Xturb[1, i]), radius=turbine_radius, fill=False, color=turbine_color, zorder=5)
    ax[0].add_patch(c)

# add potential locations
ax[0].scatter(pot_loc[0,:], pot_loc[1,:], s=1, color=pot_loc_color, zorder=10)

# load local search data
n = 83
file_name_local_search = os.path.join(path, "local_search_" + str(n) + ".pickle")

with open(file_name_local_search, "rb") as fh:
    dict_local_search = pickle.load(fh)

Xturb = dict_local_search["layout"]
pot_loc = dict_local_search["potential_locations"]
polys = dict_local_search["poly"]

# plotly code for local search
# fig = go.Figure()
# fig.add_trace(go.Scatter(x=Xturb[0, :], y=Xturb[1, :], name="Turbines location", mode="markers",
#                          marker=dict(size=12, color="#85C0F9")))
# fig.add_trace(go.Scatter(x=pot_loc[0, :], y=pot_loc[1, :], name="Potential locations", mode="markers",
#                                  marker=dict(size=6, color="#F5793A")))
# for n_poly, poly in enumerate(polys):
#     x, y = poly["x"], poly["y"]
#     fig.add_trace(
#         go.Scatter(x=x, y=y, name="Boundary " + str(n_poly), mode="lines", line=dict(color="black")))
# fig.update_layout(
#     yaxis=dict(
#         scaleanchor="x",
#         scaleratio=1,
#     ),
#     template="simple_white"
# )
# fig.show()

# pyplot code for local search figure 
# add boundaries
for n_poly, poly in enumerate(polys):
    x, y = poly["x"], poly["y"]
    ax[1].plot(x, y, color=boundary_color, zorder=0)

# add turbines
for i in np.arange(0, len(Xturb[0,:])):
    c = patches.Circle((Xturb[0, i], Xturb[1, i]), radius=turbine_radius, fill=False, color=turbine_color, zorder=5)
    ax[1].add_patch(c)

# add potential locations
ax[1].scatter(pot_loc[0,:], pot_loc[1,:], s=1, color=pot_loc_color, zorder=10)

# label figures 
ax[0].annotate("Boundaries", (7600, 9200), color=boundary_color)
ax[0].annotate("Wind Turbines", (7600, 8700), color=turbine_color)
ax[0].annotate("Potential Locations", (7600, 8200), color=pot_loc_color)

# format figure
fontsize = 10
for axi in ax:
    axi.xaxis.set_ticks_position("none")
    axi.yaxis.set_ticks_position("none")
    axi.set_xticks([])
    axi.set_yticks([])
    # ax[2].tick_params(axis="x", pad=12)

    # # ax[1].set_title("(a)", y=-0.25,fontsize=fontsize)
    # # ax[2].set_title("(b)", y=-0.25,fontsize=fontsize)

    axi.spines["top"].set_visible(False)
    axi.spines["bottom"].set_visible(False)
    axi.spines["left"].set_visible(False)
    axi.spines["right"].set_visible(False)

    axi.axis=("square")
    axi.set(aspect='equal')
    
    # plt.gcf().set_aspect('equal')

ax[0].set_title("(a)", y=0,fontsize=fontsize)
ax[1].set_title("(b)", y=0,fontsize=fontsize)


plt.tight_layout()
# save figure
plt.savefig("GreedyLS.pdf", transparent=True)

plt.show()