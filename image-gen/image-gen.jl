using PyPlot; const plt=PyPlot
using CSV, DataFrames, DelimitedFiles
using Colors, ColorSchemes
using Statistics
using LaTeXStrings
using FLOWFarm; const ff=FLOWFarm

linestyles = linestyle_tuple = [(0, (1, 10)),(0, (1, 1)),(0, (1, 1)),(0, (5, 10)),(0, (5, 5)),(0, (5, 1)),(0, (3, 10, 1, 10)),(0, (3, 5, 1, 5)),(0, (3, 1, 1, 1)),(0, (3, 5, 1, 5, 1, 5)),(0, (3, 10, 1, 10, 1, 10)),(0, (3, 1, 1, 1, 1, 1))]

function custum_color_map(;idx=[3, 1, 4], asarray=false)
    
    if asarray
        colors = ["Gray", "#BDB8AD", "#85C0F9", "#0F2080", "#F5793A", "#A95AA1", "#382119", "#CCBE95", "#382119"]
        return colors
    else
        colors = [colorant"#BDB8AD", colorant"#85C0F9", colorant"#0F2080", colorant"#F5793A", colorant"#A95AA1", colorant"#382119", colorant"#CCBE95", colorant"#382119"]
        return plt.ColorMap("BlueGrayOrange", colors[idx])
    end
end

function read_convergence_histories(filepath)
    re_comment = r"#"               # regular expression to find comments
    re_best_id = r"(?<=ID: )\d*"    # regular expression to find best opt id
    re_opt_id = r"(?<=opt. )\d*"    # regular expression to find current opt id
    opt_ids = Int[]                 # container for opt IDs
    line = 0                        # counter to track current line number in the file
    best_id = 0                     # id of best optimization
    aep_row = false                 # boolean to track whether we are on an fcalls row or an aep row 
    aep = Vector{Vector{Float64}}() # empty vector of vectors to hold aep results 
    fcalls = Vector{Vector{Int}}()  # empty dict to hold fcall results
    open(filepath, "r") do f
        # read through file 
        while ! eof(f)
            # read in current line
            s = readline(f)
            # increment line counter
            line+= 1
            println(line)
            # skip the first line
            if line == 1
                continue
            end
            # check if the current line contains a comment
            if occursin(re_comment, s)
                # check if the ccurrent line contains the id of the best optimization run
                if occursin(re_best_id, s)
                    # if on best id row, get regex match object
                    m = match(re_best_id, s)
                    # parse regex object for best opt id as an int
                    best_id = parse(Int, m.match)
                    # println("best id: ", best_id)
                    continue
                # if we parsed a row of aep, then get next opt id and set aep row flag to false
                elseif !aep_row
                    # get regex match object
                    m = match(re_opt_id, s)
                    append!(opt_ids, [parse(Int, m.match)])
                end
            else
                if aep_row
                    println(s[1:10])
                    aeptemp = parse.(Float64, split(s, ", "))
                    push!(aep, aeptemp)
                    aep_row = false
                else
                    fcallstemp = parse.(Int, split(s, ", "))
                    push!(fcalls, fcallstemp)
                    aep_row = true
                end
            end
        end
    end

    return best_id, opt_ids, fcalls, aep
    
end

function windrose(colors; save_image=false, show_image=false, fontsize=10)
    # load data 
    datafile = "../src/input-files/wind/iea37-windrose-cs4.yaml"
    dir, speed, freq, ti = ff.get_wind_rose_YAML(datafile)

    # set up throw away data required for wind rose
    measurement_heights = ones(length(dir))
    shearexponent = 0.12539210313906432
    groundheight = 0.0
    shear_order = "first"
    wind_shear_model = ff.PowerLawWindShear(shearexponent, groundheight, shear_order)
    air_density = 1.1716  # kg/m^3

    # get unique values
    du = unique(dir)
    fdu = [sum(freq[dir.==du[i]]) for i=1:length(du)]
    su = unique(speed)
    fsu = 100*[sum(freq[speed.==su[i]]) for i=1:length(su)]./360
    fsu ./= sum(fsu)
    println(sum(fsu))
    # # initialize windrose
    # windrose = ff.DiscretizedWindResource(dir, speed, freq, measurement_heights, air_density, ti*ones(length(dir)), wind_shear_model)

    # initialize figure and axes
    fig = plt.figure(figsize=(8,4))
    ax1 = plt.subplot(121, projection="polar")
    ax2 = plt.subplot(122)
    
    # # plot wind roses on axes    
    scalar = 1E2
    fticks = 0.1:0.1:0.5

    rcParams = plt.PyDict(PyPlot.matplotlib."rcParams")
    rcParams["font.size"] = fontsize

    # plot frequency
    dlabels=[L"E, $90\degree$","NE",L"N, $0\degree$","NW",L"W, $270\degree$","SW",L"S, $180\degree$ ","SE"]
    ff.plotwindrose!(ax1, du, fdu*scalar; dlabels=dlabels, fticks=fticks, rlabel_position=45, roundingdigit=3,fontsize=fontsize, units="%",kwargs=(:edgecolor=>nothing, :alpha=>1.0, :color=>colors[2]))
    
    # plot wind speed 
    ax2.plot(su, fsu*scalar, "o", markersize=4, color=colors[2])
    ax2.set(xlabel=L"Wind Speed (m s$^{-1}$)", ylabel="Wind Speed Probability (%)")
    ax2.set(ylim=[0,12], yticks=0:2:12)
    # # format
    ax1.tick_params(axis="x", pad=12)
    # ax[2].tick_params(axis="x", pad=12)

    ax1.set_title("(a)", y=-0.35,fontsize=fontsize)
    ax2.set_title("(b)", y=-0.35,fontsize=fontsize)
    # # ax[1].set_title("(a)", y=-0.25,fontsize=fontsize)
    # # ax[2].set_title("(b)", y=-0.25,fontsize=fontsize)

    ax2.spines["top"].set_visible(false)
    ax2.spines["bottom"].set_visible(true)
    ax2.spines["left"].set_visible(true)
    ax2.spines["right"].set_visible(false)
    plt.tight_layout()

    # save figure
    if save_image
        plt.savefig("images/windresource360.pdf", transparent=true)
    end

    # show figure
    if show_image
        plt.show()
    end

end

function base_layout(colors; save_image=false, show_image=false, fontsize=10)
    # read data
    filepath = "../src/input-files/"
    boundary_file = filepath*"farms/iea37-boundary-cs4.yaml"
    boundary_vertices = ff.get_boundary_yaml(boundary_file)
    layout_file = filepath*"farms/iea37-ex-opt4.yaml"
    turbine_x, turbine_y, fname_turb, fname_wr = ff.get_turb_loc_YAML(layout_file)
    turb_ci, turb_co, rated_ws, rated_pwr, turb_diam, turb_height = ff.get_turb_atrbt_YAML(filepath*"turbines/"*fname_turb)

    # find how many turbines in each region 
    nregions = 5
    nturbines = length(turbine_x)
    
    # initialize plots 
    fig, ax = plt.subplots(1)

    # plot farm 
    ff.plotwindfarm!(ax, turbine_x, turbine_y, turb_diam*ones(length(turbine_x)); nboundaries=5, 
    boundary_vertices=boundary_vertices, aspect="equal", xlim=[], ylim=[], fill=false, turbinecolor=colors[3], 
    boundarycolor=colors[1], boundarylinestyle="--", turbinelinestyle="-", markeralpha=1, title="")

    # label turbines 
    ax.annotate("Wind Turbines", (7600, 8500), color=colors[3])

    # label regions
    ax.annotate("Boundaries", (7600, 9000), color=colors[1])
    ax.annotate("(1)", (6900, 1300), color="k")
    ax.annotate("(2)", (4545, 3700), color="k")
    ax.annotate("(3)", (2280, 5800), color="k")
    ax.annotate("(4)", (1600, 10100), color="k")
    ax.annotate("(5)", (5800, 11400), color="k")
    # ax.annotate("Boundaries", (7600, 9000), color=colors[2])
    # ax.annotate("(IIIa)", (median(boundary_vertices[1][:,1]), median(boundary_vertices[1][:,2])), color="k")
    # ax.annotate("(IIIb)", (median(boundary_vertices[2][:,1]), median(boundary_vertices[2][:,2])), color="k")
    # ax.annotate("(IVa)", (median(boundary_vertices[3][:,1]), median(boundary_vertices[3][:,2])), color="k")
    # ax.annotate("(IVb)", (median(boundary_vertices[4][:,1]), median(boundary_vertices[4][:,2])), color="k")
    # ax.annotate("(IVc)", (median(boundary_vertices[5][:,1]), median(boundary_vertices[5][:,2])), color="k")

    # add compass rose 
    lengtharrow = 1200
    xarrow = minimum(turbine_x)
    yarrow = minimum(turbine_y)+lengtharrow
    ax.annotate("N", xy=(xarrow, yarrow), xytext=(xarrow, yarrow-lengtharrow),
            arrowprops=Dict("fill"=>false, "width"=>3, "headwidth"=>9),
            ha="center", va="center", fontsize=fontsize)

    # format
    ax.spines["top"].set_visible(false)
    ax.spines["bottom"].set_visible(false)
    ax.spines["left"].set_visible(false)
    ax.spines["right"].set_visible(false)
    ax.tick_params(left=false, labelleft=false, bottom=false, labelbottom=false)
    plt.tight_layout()

    # # save figure
    if save_image
        plt.savefig("images/layout_base.pdf", transparent=true)
    end

    # show figure
    if show_image
        plt.show()
    end
end

function print_allocation_table()
    # set paths
    layoutpath = "../results/optimization-results/"

    # what are the files called
    filenames = ["base.yaml",
                "snoptwec.yaml",
                "debo.yaml",
                "gps.yaml",
                "cmaes.yaml",
                "gagb.yaml",
                "adremog.yaml",
                "pg.yaml",
                "dpa.yaml"]

    boundarypath = "../src/input-files/"
    boundary_file = boundarypath*"farms/iea37-boundary-cs4.yaml"

    # how many layouts
    n = length(filenames)

    # set names
    names = ["Provided", "SNOPT+WEC", "DEBO", "GPS", "CMA-ES", "GA-GB", "ADREMOG", "PG", "DPA"]

    # load boundary
    boundary_vertices = ff.get_boundary_yaml(boundary_file)

    # how many regions in boundary
    nregions = size(boundary_vertices)[1]
    println("nregions: $nregions")

    # get boundary normals 
    boundary_normals = ff.boundary_normals_calculator(boundary_vertices; nboundaries=nregions)

    # order regions
    region_names = [1, 2, 4, 3, 5]

    # print table header
    println("\\begin{table}[h!]")
    println("\\caption{Turbine-to-region allocation for each algorithm's best layout. All layouts have a total of 81 turbines.}")
    println("\\label{tab:allocation}")
    println("\\begin{center}")
    println("\\begin{tabular}{rrrrrr}")
    println(" & \\multicolumn{5}{c}{\\textbf{Region}} \\\\")
    println("\\cline{2-6}")
    println("  & \\multicolumn{1}{r}{\\textbf{1}} & \\multicolumn{1}{r}{\\textbf{2}} & \\multicolumn{1}{r}{\\textbf{3}} & \\multicolumn{1}{r}{\\textbf{4}} & \\multicolumn{1}{r}{\\textbf{5}} \\\\ \\hline")

    # loop over all regions
    for i = 1:n

        # get full filename
        layout_file = layoutpath*filenames[i]

        # load layout
        turbine_x, turbine_y, fname_turb, fname_wr = ff.get_turb_loc_YAML(layout_file)
    
        # get number of turbines in layout
        nturbines = length(turbine_x)
    
        # determine which turbines are in which region
        cons, region = ff.ray_casting_boundary(boundary_vertices, boundary_normals, turbine_x, turbine_y; discrete=true, s=700, tol=5E-1, return_region=true)
    
        # print beginning of line 
        print("\\textbf{$(names[i])} ")

        sumterm = 0
        for i = 1:nregions
            sumterm += count(==(i), region)
            # print turbines in region
            print("& $(count(==(region_names[i]), region)) ")
        end

        # print new line character
        print("\\\\\n")
        
    end
    # print end matter 
    println("\\hline")
    println("\\end{tabular}")
    println("\\end{center}")
    println("\\end{table}")
end

function plot_all_layouts(colors; save_image=false, show_image=false, fontsize=10)
    # set paths
    layoutpath = "../results/optimization-results/"

    filenames = ["base.yaml",
                "snoptwec.yaml",
                "debo.yaml",
                "gps.yaml",
                "cmaes.yaml",
                "gagb.yaml",
                "adremog.yaml",
                "pg.yaml",
                "dpa.yaml"]

    boundarypath = "../src/input-files/"
    boundary_file = boundarypath*"farms/iea37-boundary-cs4.yaml"

    # how many layouts
    n = length(filenames)

    # set names
    names = ["Provided", "SNOPT+WEC", "DEBO", "GPS", "CMA-ES", "GA-GB", "ADREMOG", "PG", "DPA"]
    labels = ["(a)", "(b)", "(c)", "(d)", "(e)", "(f)", "(g)", "(h)", "(i)"]

    # load boundary
    boundary_vertices = ff.get_boundary_yaml(boundary_file)

    # how many regions in boundary
    nregions = size(boundary_vertices)[1]

    # initialize figure layout
    fig, axs = plt.subplots(3,3,figsize=(8,11))

    # loop over all algorithms
    i = 0
    for j = 1:3
        for k = 1:3
            i += 1
            ax = axs[j, k]
            # get full filename
            layout_file = layoutpath*filenames[i]

            # load layout
            turbine_x, turbine_y, fname_turb, fname_wr = ff.get_turb_loc_YAML(layout_file)
            
            # get turbine diameter
            turb_ci, turb_co, rated_ws, rated_pwr, turb_diam, turb_height = ff.get_turb_atrbt_YAML(boundarypath*"turbines/"*fname_turb)

            # get number of turbines in layout
            nturbines = length(turbine_x)

            # plot layout
            ff.plotwindfarm!(ax, turbine_x, turbine_y, turb_diam*ones(length(turbine_x)); nboundaries=nregions, 
            boundary_vertices=boundary_vertices, aspect="equal", xlim=[], ylim=[], fill=false, turbinecolor=colors[3], 
            boundarycolor=colors[1], boundarylinestyle="-", turbinelinestyle="-", markeralpha=1, title="")

            # title 
            ax.set_title("$(labels[i]) $(names[i])", loc="left")

            

            # label regions
            if i == 1
                # label turbines 
                ax.annotate("Wind Turbines", (7600, 8100), color=colors[3])
                ax.annotate("Boundaries", (7600, 9000), color=colors[1])
                ax.annotate("(1)", (6500, 900), color="k")
                ax.annotate("(2)", (4145, 3300), color="k")
                ax.annotate("(3)", (1880, 5400), color="k")
                ax.annotate("(4)", (1000, 10200), color="k")
                ax.annotate("(5)", (5800, 11600), color="k")

                # add compass rose 
                lengtharrow = 2400
                xarrow = minimum(turbine_x)
                yarrow = minimum(turbine_y)+lengtharrow
                ax.annotate("N", xy=(xarrow, yarrow), xytext=(xarrow, yarrow-lengtharrow),
                        arrowprops=Dict("fill"=>false, "width"=>3, "headwidth"=>9),
                        ha="center", va="center", fontsize=fontsize)
            end
            # format
            ax.spines["top"].set_visible(false)
            ax.spines["bottom"].set_visible(false)
            ax.spines["left"].set_visible(false)
            ax.spines["right"].set_visible(false)
            ax.tick_params(left=false, labelleft=false, bottom=false, labelbottom=false)
        end
    end
    plt.tight_layout()
    # save figure
    if save_image
        plt.savefig("images/all-layouts.pdf", transparent=true)
    end

    # show figure
    if show_image
        plt.show()
    end
end

function plot_simple_design_space!(colors; ax=nothing, save_image=false, show_image=false)
    
    turbine_y = -[0.0 3.0 7.0]
    turbine_x = [-1.0 1.0 0.0]
    diameter = 1.0

    if ax === nothing
        fig, ax = plt.subplots(1, figsize=(5, 6))
    end

    # show downstream turbine movement
    steps = 5
    alphas = range(0.9, 0.5, length=steps)
    locs = range(minimum(turbine_x)-3.0, turbine_x[3], length=steps)

    for i=1:steps
        blade1 = matplotlib.patches.Ellipse((locs[i]+diameter/4, turbine_y[3]), diameter / 2, diameter/12, facecolor="$(alphas[i])", edgecolor="none", fill=true,
                            alpha=1.0, linestyle="-", visible=true)
        blade2 = matplotlib.patches.Ellipse((locs[i]-diameter/4, turbine_y[3]), diameter / 2, diameter / 12, facecolor="$(alphas[i])", edgecolor="none", fill=true,
                         alpha=1.0, linestyle="-", visible=true)
        hub = matplotlib.patches.Rectangle((locs[i] - diameter / 16, turbine_y[3]-diameter/8), diameter / 8, diameter / 4, facecolor="$(alphas[i])",
                         edgecolor="none", fill=true, alpha=1.0, linestyle="-", visible=true, joinstyle="round")
        clip1 = matplotlib.patches.Rectangle((locs[i] +1/16.0 , turbine_y[3] - diameter / 8), diameter, diameter / 4,
                          facecolor="none",
                          edgecolor="none", fill=true, alpha=alphas[i], linestyle="-", visible=true, joinstyle="round")
        clip2 = matplotlib.patches.Rectangle((locs[i] - diameter * 17 / 16, turbine_y[3] - diameter / 8), diameter, diameter / 4,
                        facecolor="none",
                        edgecolor="none", fill=true, alpha=alphas[i], linestyle="-", visible=false, joinstyle="round")
        ax.add_artist(blade1)
        ax.add_artist(blade2)
        ax.add_artist(hub)
        ax.add_artist(clip1)
        ax.add_artist(clip2)
        blade1.set_clip_path(clip1)
        blade2.set_clip_path(clip2)
    end
    tc = "k"
    # plot turbine locations
    for i=1:3

        wake = matplotlib.patches.Polygon([[turbine_x[i]-0.5, turbine_y[i]],
                                 [turbine_x[i]-1.5, turbine_y[i]-9.0],
                                 [turbine_x[i]+1.5, turbine_y[i]-9.0],
                                 [turbine_x[i]+0.5, turbine_y[i]]], color=colors[2], alpha=0.2, closed=true)
        ax.add_artist(wake)

        blade1 = matplotlib.patches.Ellipse((turbine_x[i]+diameter/4, turbine_y[i]), diameter / 2, diameter / 12, facecolor=tc, edgecolor="none", fill=true,
                         alpha=1.0, linestyle="-", visible=true)
        blade2 = matplotlib.patches.Ellipse((turbine_x[i] - diameter / 4, turbine_y[i]), diameter / 2, diameter / 12, facecolor=tc,
                         edgecolor="none", fill=true,
                         alpha=1.0, linestyle="-", visible=true)
        hub = matplotlib.patches.Rectangle((turbine_x[i]-diameter/16, turbine_y[i] - diameter / 8), diameter / 8, diameter / 4,
                        facecolor=tc,
                        edgecolor="none", fill=true, alpha=1.0, linestyle="-", visible=true, joinstyle="round")
        ax.add_artist(blade1)
        ax.add_artist(blade2)
        ax.add_artist(hub)
    end
    # add arrow to indicate movement
    ax.arrow(turbine_x[3]+.75, turbine_y[3], 1.5, 0.0, width=0.05, color="k", fc="k", ec="k")

    ax.spines["top"].set_visible(false)
    ax.spines["right"].set_visible(false)
    ax.spines["left"].set_visible(false)
    ax.spines["bottom"].set_visible(true)
    ax.set_xlabel(L"$\Delta y/d$")

    ax.set_xticks([-4.0, 0.0, 4.0])
    ax.set_yticks([])

    ax.set_ylim([-9.0, 5.0])
    ax.set_xlim([-5.0, 5.0])

    ax.yaxis.set_ticks_position("none")
    ax.xaxis.set_ticks_position("bottom")
    #
    plt.tight_layout()

    plt.show()
    if save_image
        plt.savefig("3-turb-farm-wec-example.pdf", transparent=true)
    end
    if show_image
        plt.show()
    end

end

function plot_smoothing_visualization_w_wec_wo_wec!(colors; ax=nothing, save_image=false, show_image=false)

    # load data
    data = readdlm("image-data/wec-ex-data.txt", ',', skipstart=1)
    println(data)
    wec_values = [1, 2.0, 3.0]
    xt = [-1.6, -1.5, -2.75]
    yt = [240, 185, 160]

    location = data[:, 4]

    if ax === nothing
        fig, ax = plt.subplots(1)
    end

    linetypes = ["-", "--", ":", "-.", (0, (3, 2, 1, 2, 1, 2)), (0, (3, 2, 3, 2, 1, 2))]
    
    plot_vals = 1:length(wec_values)

    for i = 1:length(plot_vals)
        println(i)
        ax.plot(location, data[:, plot_vals[i]], color=colors[i], linestyle=linetypes[i])   
        text_label = L"$\xi$ = "*"$(wec_values[plot_vals[i]])"
        plt.text(xt[i], yt[i], text_label, color=colors[i], fontsize=14)
    end

    ax.set_xlabel(L"$\Delta y/d$")
    ax.set_ylabel("AEP (GWh)")
    ax.set_ylim([125, 275])
    ax.set_xlim([-4, 4])
    plt.yticks(range(125, 275, length=3))
    plt.xticks([-4, 0, 4])
    # ax.legend(ncol=2, loc=2, frameon=false, )  # show plot
    # tick_spacing = 1
    # ax.xaxis.set_major_locator(ticker.MultipleLocator(tick_spacing))
    #
    ax.spines["top"].set_visible(false)
    ax.spines["right"].set_visible(false)

    # ax(square=true)
    # ax.set(adjustable="box-forced")
    #
    plt.tight_layout()

    if save_image
        plt.savefig("wec.pdf", transparent=true)
    end

    if show_image
        plt.show()
    end
    
end

function plot_wec_example_compound(colors; save_image=false, show_image=false, fontsize=10)

    # initialize figure and axes 
    fig, ax = plt.subplots(1, 2, figsize=(10,5))#subplot_kw=Dict("box_aspect"=>1))

    # add simple layout 
    ax[1].set(aspect="auto")
    plot_simple_design_space!(colors; ax=ax[1])

    # add AEP curves
    plot_smoothing_visualization_w_wec_wo_wec!(colors; ax=ax[2])
    ax[2].set(aspect="auto")

    # format 
    ax[1].text(0.0, -12.0, "(a)", fontsize=fontsize, ha="center")
    ax[2].text(0.0, 93, "(b)", fontsize=fontsize, ha="center")
    plt.tight_layout()

    if save_image
        plt.savefig("images/wec.pdf", transparent=true)
    end

    if show_image
        plt.show()
    end

end

function improvement()
    aep_ff = readdlm("../src/202111081620-run-with-provided-model/recalcaep-python.txt",skipstart=1)
    subs_ff = [0, 1, 2, 5, 3, 8, 4, 7, 6]
    algs = ["Base", "SNOPT+WEC", "DEBO", "GPS", "CMA-ES", "GA-GB", "ADREMOG", "PG", "DPA"]
    for i=1:length(algs)
        println("$(algs[i]): $(round(aep_ff[i], digits=7)*1E-3), $(round(100*(aep_ff[i]-aep_ff[1])/aep_ff[1],digits=3))")
    end
end

function make_images()

    # check if images directory exists, otherwise create it
    isdir("images") || mkdir("images")

    # set up general formatting
    fontsize = 10
    colors = ["#BDB8AD", "#85C0F9", "#0F2080", "#F5793A", "#A95AA1", "#382119"]

    rcParams = PyPlot.matplotlib.rcParams
    rcParams["font.size"] = fontsize
    rcParams["lines.markersize"] = 1
    rcParams["axes.prop_cycle"] = colors

    # flags of what to do with created images
    save_image = true 
    show_image = true

    ####### Function calls to generate images and tables. Uncomment the call for the figures/tables you want to generate #######

    windrose(colors; save_image=save_image, show_image=show_image, fontsize=fontsize)

    base_layout(colors; save_image=save_image, show_image=show_image)

    plot_wec_example_compound(colors; save_image=save_image, show_image=show_image, fontsize=fontsize)
    
    print_allocation_table()

    plot_all_layouts(colors; save_image=save_image, show_image=show_image, fontsize=10)
    
end