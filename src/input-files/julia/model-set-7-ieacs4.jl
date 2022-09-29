# @everywhere import FLOWFarm; const ff = FLOWFarm
import FLOWFarm; const ff = FLOWFarm
using YAML

function wind_farm_setup(;layout=1, reduce_wind_rose=false, nrotorpoints=1, nturbines=81, ndirs=360)
    # based on IEA case study 4

    # set initial turbine x and y locations
    

    
    layout_file_name = "../input-files/farms/iea37-ex-opt4.yaml"
    turbine_x, turbine_y, fname_turb, fname_wr = ff.get_turb_loc_YAML(layout_file_name)

    turbine_x = turbine_x[1:nturbines]
        turbine_y = turbine_y[1:nturbines]

    # set turbine base heights
    turbine_z = zeros(nturbines)

    # set turbine yaw values
    turbine_yaw = zeros(nturbines)

    # set turbine design parameters
    turbine_file_name = string("../input-files/turbines/",fname_turb)
    turb_ci, turb_co, rated_ws, rated_pwr, turb_diam, turb_hub_height = ff.get_turb_atrbt_YAML(turbine_file_name)

    rotor_diameter = zeros(nturbines) .+ turb_diam # m
    hub_height = zeros(nturbines) .+ turb_hub_height   # m
    cut_in_speed = zeros(nturbines) .+ turb_ci  # m/s
    cut_out_speed = zeros(nturbines) .+ turb_co  # m/s
    rated_speed = zeros(nturbines) .+ rated_ws # m/s
    rated_power = zeros(nturbines) .+ rated_pwr # W
    generator_efficiency = ones(nturbines)

    # rotor swept area sample points (normalized by rotor radius)
    rotor_points_y, rotor_points_z = ff.rotor_sample_points(nrotorpoints)

    # set up wind farm boundary
    boundary_file_name = string("../input-files/farms/iea37-boundary-cs4.yaml")
    boundary_vertices = ff.get_boundary_yaml(boundary_file_name)
    boundary_normals = ff.boundary_normals_calculator(boundary_vertices,nboundaries=length(boundary_vertices))
    
    # set flow parameters
    windrose_file_name = string("../input-files/wind/",fname_wr)
    if reduce_wind_rose
        winddirections, windspeeds, windprobabilities, ambient_ti = ff.get_reduced_wind_rose_YAML(windrose_file_name)
    else
        winddirections, windspeeds, windprobabilities, ambient_ti = ff.get_wind_rose_YAML(windrose_file_name)
    end

    nstates = length(winddirections)
    winddirections *= pi/180.0

    air_density = 1.1716  # kg/m^3
    shearexponent = 0.0
    ambient_tis = zeros(nstates) .+ ambient_ti
    measurementheight = zeros(nstates) .+ turb_hub_height

    # initialize power model
    power_model = ff.PowerModelPowerCurveCubic()
    power_models = Vector{typeof(power_model)}(undef, nturbines)
    for i = 1:nturbines
        power_models[i] = power_model
    end

    # load thrust curve
    ct = 4.0*(1.0/3.0)*(1.0 - 1.0/3.0)

    # initialize thurst model
    ct_model = ff.ThrustModelConstantCt(ct)
    ct_models = Vector{typeof(ct_model)}(undef, nturbines)
    for i = 1:nturbines
        ct_models[i] = ct_model
    end

    # initialize wind shear model
    wind_shear_model = ff.PowerLawWindShear(shearexponent, 0.0, "none")

    # get sorted indecies 
    sorted_turbine_index = sortperm(turbine_x)

    # initialize the wind resource definition
    wind_resource = ff.DiscretizedWindResource(winddirections, windspeeds, windprobabilities, measurementheight, air_density, ambient_tis, wind_shear_model)

    if ndirs < length(wind_resource.wind_directions) && reduce_wind_rose
        println("WARNING: reducing wind directions to $ndirs from $(length(wind_resource.wind_directions))")
        wind_resource = ff.rediscretize_windrose(wind_resource, ndirs; start=0.0, averagespeed=true)
    end

    # set up wake and related models
    k = 0.0324555
    wakedeficitmodel = ff.GaussSimple(k)

    wakedeflectionmodel = ff.NoYawDeflection()
    # wakedeflectionmodel = ff.JiminezYawDeflection()
    wakecombinationmodel = ff.SumOfSquaresFreestreamSuperposition()
    localtimodel = ff.LocalTIModelNoLocalTI()

    # initialize model set
    model_set = ff.WindFarmModelSet(wakedeficitmodel, wakedeflectionmodel, wakecombinationmodel, localtimodel)

    return turbine_x, turbine_y, turbine_z, turbine_yaw, rotor_diameter, hub_height, cut_in_speed, 
    cut_out_speed, rated_speed, rated_power, generator_efficiency, 
    rotor_points_y, rotor_points_z, winddirections, windspeeds, windprobabilities, 
    air_density, ambient_ti, shearexponent, ambient_tis, measurementheight, power_models, 
    ct_models, wind_shear_model, sorted_turbine_index, wind_resource, wakedeficitmodel, 
    wakedeflectionmodel, wakecombinationmodel, localtimodel, model_set, boundary_vertices, boundary_normals

end

# turbine_x, turbine_y, turbine_z, turbine_yaw, rotor_diameter, hub_height, cut_in_speed, 
# cut_out_speed, rated_speed, rated_power, generator_efficiency, 
# rotor_points_y, rotor_points_z, winddirections, windspeeds, windprobabilities, 
# air_density, ambient_ti, shearexponent, ambient_tis, measurementheight, power_models, 
# ct_models, wind_shear_model, sorted_turbine_index, wind_resource, wakedeficitmodel, 
# wakedeflectionmodel, wakecombinationmodel, localtimodel, model_set, boundary_vertices, 
# boundary_normals = wind_farm_setup()