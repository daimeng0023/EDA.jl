module EDA

using CImGui
using CImGui.CSyntax
using CImGui.CSyntax.CStatic
using CImGui.GLFWBackend
using CImGui.OpenGLBackend
using CImGui.GLFWBackend.GLFW
using CImGui.OpenGLBackend.ModernGL
using CImGui: ImVec2, ImVec4, IM_COL32, ImS32, ImU32, ImS64, ImU64
using Printf
using DataFrames
using Gadfly
using CSV
using Images
#using Plots

include("new_GUI.jl")

export
    parse_file,
    launch

end # module
