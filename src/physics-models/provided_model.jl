using FLOWFarm; const ff=FLOWFarm
using CSV
using DataFrames
using DelimitedFiles

# import model set with wind farm and related details
include("../input-files/julia/model-set-7-ieacs4.jl")

# set globals struct for use in wrapper functions
mutable struct params_struct{TF, TAF, TAAF, MS, TACT, TAW, TAP}
    model_set::MS
    rotor_points_y::TAF
    rotor_points_z::TAF
    turbine_z::TAF
    ambient_ti::TF
    rotor_diameter::TAF
    boundary_vertices::TAAF
    boundary_normals::TAAF
    obj_scale::TF
    con_scale_boundary::TF
    xyscale::TF
    hub_height::TAF
    turbine_yaw::TAF
    ct_models::TACT
    generator_efficiency::TAF
    cut_in_speed::TAF
    cut_out_speed::TAF
    rated_speed::TAF
    rated_power::TAF
    wind_resource::TAW
    power_models::TAP
end

# set up objective wrapper function
function aep_wrapper(x, params)
    # include relevant globals
    turbine_z = params.turbine_z
    rotor_diameter = params.rotor_diameter
    hub_height = params.hub_height
    turbine_yaw =params.turbine_yaw
    ct_models = params.ct_models
    generator_efficiency = params.generator_efficiency
    cut_in_speed = params.cut_in_speed
    cut_out_speed = params.cut_out_speed
    rated_speed = params.rated_speed
    rated_power = params.rated_power
    wind_resource = params.wind_resource
    power_models = params.power_models
    model_set = params.model_set
    rotor_points_y = params.rotor_points_y
    rotor_points_z = params.rotor_points_z
    obj_scale = params.obj_scale

    # get number of turbines
    nturbines = Int(length(x)/2)

    # extract x and y locations of turbines from design variables vector
    turbine_x = x[1:nturbines] 
    turbine_y = x[nturbines+1:end]
    
    # calculate AEP
    AEP = obj_scale*ff.calculate_aep(turbine_x, turbine_y, turbine_z, rotor_diameter,
                hub_height, turbine_yaw, ct_models, generator_efficiency, cut_in_speed,
                cut_out_speed, rated_speed, rated_power, wind_resource, power_models, model_set,
                rotor_sample_points_y=rotor_points_y,rotor_sample_points_z=rotor_points_z, 
                hours_per_year=365.0*24.0)
                
    # return the objective as an array
    return AEP
end

function run_analysis(filename, model_set_in; idealaep=false, reduce_wind_rose=true, plotresults=false, verbose=true, nrotorpoints=1, alpha=0, savehistory=false, runbase=false)
    
    obj_scale = 1.0
    con_scale_boundary = 1.0
    xyscale = 1.0

    # get wind farm setup
    turbine_x, turbine_y, turbine_z, turbine_yaw, rotor_diameter, hub_height, cut_in_speed, 
    cut_out_speed, rated_speed, rated_power, generator_efficiency, 
    rotor_points_y, rotor_points_z, winddirections, windspeeds, windprobabilities, 
    air_density, ambient_ti, shearexponent, ambient_tis, measurementheight, power_models, 
    ct_models, wind_shear_model, sorted_turbine_index, wind_resource, wakedeficitmodel, 
    wakedeflectionmodel, wakecombinationmodel, localtimodel, model_set, boundary_vertices, 
    boundary_normals = wind_farm_setup(reduce_wind_rose=reduce_wind_rose, nrotorpoints=nrotorpoints)

    nturbines = length(turbine_x)

    # replace model set
    model_set = model_set_in

    # replace layout with optimized layout
    if !idealaep
        turbine_x, turbine_y, fname_turb, fname_wr, aep_provided = ff.get_turb_loc_YAML(filename, returnaep=true) 
    else
        aep_provided = NaN
    end

    # initialize params
    params = params_struct(model_set, rotor_points_y, rotor_points_z, turbine_z, ambient_ti, 
        rotor_diameter, boundary_vertices, boundary_normals, obj_scale, con_scale_boundary, xyscale, hub_height, turbine_yaw, 
        ct_models, generator_efficiency, cut_in_speed, cut_out_speed, rated_speed, rated_power, 
        wind_resource, power_models)
    
    # initialize design variable array
    x0 = [copy(turbine_x);copy(turbine_y)]
    
    # report initial objective value
    if !idealaep
        aep = aep_wrapper(x0, params)[1]
    else
        aep = nturbines*aep_wrapper([0.0, 0.0], params)[1]
    end
    if verbose
        println("AEP: ", aep)
    end

    # add initial turbine location and boundary to plot
    if plotresults
        fig, axlayout = plt.subplots(1)
        ff.plotwindfarm!(axlayout, turbine_x, turbine_y, rotor_diameter; nboundaries=5, boundary_vertices=boundary_vertices, 
            aspect="equal", xlim=[], ylim=[], fill=false, turbinecolor="k", boundarycolor="k", 
            boundarylinestyle="--", markeralpha=1, title="")
        plt.show()
    end

    if !idealaep
        return aep, aep_provided
    else
        return aep
    end

end

function calculate_aep(filepath; reduce_wind_rose=false, nrotorpoints=1)

    model_set_gauss_simple = ff.WindFarmModelSet(ff.GaussSimple(0.0324555), ff.JiminezYawDeflection(), ff.SumOfSquaresFreestreamSuperposition(), ff.LocalTIModelNoLocalTI())

    aep_out, aep_provided = run_analysis(filepath, model_set_gauss_simple, idealaep=false, reduce_wind_rose=false, plotresults=false, verbose=false, nrotorpoints=nrotorpoints, alpha=0, savehistory=false, runbase=false)
    aep_out /= 1E6
    println("aep is $(aep_out) and provided aep was $(aep_provided)")
    println("difference between aep out and provided aep is: $(round(100*(aep_provided-aep_out)/aep_provided, digits=3))%")
    return aep_out
end

function calculate_aep_all_layouts()

    # set paths
    resultsdirectory = "../../results/optimization-results/"

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

    n = length(filenames)

    # set names
    names = ["Base", "WEC", "DEBO", "GPS", "CMA-ES", "GA-GB", "ADREMOG", "PG", "DPA"]

    # calculate AEP
    AEP = zeros(n)
    for i in 1:n
        diraep = calculate_aep(resultsdirectory*filenames[i])
        AEP[i] = round(sum(diraep), digits=10)
        println(names[i], ": ", AEP[i], " MWh, improvement: $(round(100*(AEP[i]-AEP[1])/AEP[1],digits=2))")
    end

    # save results
    CSV.write("recalcaep-julia.txt", DataFrame([names, AEP], :auto))

    return
end

function get_difference()
    # difference from provided model 
    AEPpy = readdlm("recalcaep-python.txt", skipstart=1)
    AEPjl = readdlm("recalcaep-julia.txt", ',', skipstart=1)[:,2]
    diff = AEPjl .- AEPpy 
    println(100.0.*diff./AEPpy)
end

# basic call
calculate_aep_all_layouts()