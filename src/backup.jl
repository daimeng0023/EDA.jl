function launch()

    @static if Sys.isapple()
        # OpenGL 3.2 + GLSL 150
        glsl_version = 150
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 2)
        GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE) # 3.2+ only
        GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE) # required on Mac
    else
        # OpenGL 3.0 + GLSL 130
        glsl_version = 130
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 0)
        # GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE) # 3.2+ only
        # GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE) # 3.0+ only
    end

    # setup GLFW error callback
    error_callback(err::GLFW.GLFWError) = @error "GLFW ERROR: code $(err.code) msg: $(err.description)"
    GLFW.SetErrorCallback(error_callback)

    # create window
    window = GLFW.CreateWindow(1280, 720, "ElectroDermal Activity Analysis")
    @assert window != C_NULL
    GLFW.MakeContextCurrent(window)
    GLFW.SwapInterval(1)  # enable vsync

    # setup Dear ImGui context
    ctx = CImGui.CreateContext()

    # setup Dear ImGui style
    # CImGui.StyleColorsDark()
    # CImGui.StyleColorsClassic()
    CImGui.StyleColorsLight()

    # load Fonts
    # - If no fonts are loaded, dear imgui will use the default font. You can also load multiple fonts and use `CImGui.PushFont/PopFont` to select them.
    # - `CImGui.AddFontFromFileTTF` will return the `Ptr{ImFont}` so you can store it if you need to select the font among multiple.
    # - If the file cannot be loaded, the function will return C_NULL. Please handle those errors in your application (e.g. use an assertion, or display an error and quit).
    # - The fonts will be rasterized at a given size (w/ oversampling) and stored into a texture when calling `CImGui.Build()`/`GetTexDataAsXXXX()``, which `ImGui_ImplXXXX_NewFrame` below will call.
    # - Read 'fonts/README.txt' for more instructions and details.
    # fonts_dir = joinpath(@__DIR__, "..", "fonts")
    # fonts = CImGui.GetIO().Fonts
    # default_font = CImGui.AddFontDefault(fonts)
    # CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "Cousine-Regular.ttf"), 15)
    # CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "DroidSans.ttf"), 16)
    # CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "Karla-Regular.ttf"), 10)
    # CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "ProggyTiny.ttf"), 10)
    # CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "Roboto-Medium.ttf"), 16)
    # @assert default_font != C_NULL

    # setup Platform/Renderer bindings
    ImGui_ImplGlfw_InitForOpenGL(window, true)
    ImGui_ImplOpenGL3_Init(glsl_version)
    clear_color = Cfloat[0.45, 0.55, 0.60, 1.00]
    Open_files = false
    while !GLFW.WindowShouldClose(window)
        GLFW.PollEvents()
        # start the Dear ImGui frame
        ImGui_ImplOpenGL3_NewFrame()
        ImGui_ImplGlfw_NewFrame()
        CImGui.NewFrame()
        begin
            CImGui.Begin("Menu")
            CImGui.Text("Please select files that you want to Analysis.")
            @c CImGui.Checkbox("Open files", &Open_files)
            if Open_files
                #df = CSV.read("F:\\julia\\CSV\\EDA.csv", header = ["EDA"])
                df = CSV.read("F:\\julia\\CSV\\HR.csv", header = ["HR"])
                df_data =sort(Cfloat.(df[3:end,1]))
                st = df[1,1]
                freq = df[2,1]
                max_value = df_data[end,1]
                #max = Cfloat(max_value)
                #length = size(df,1)-2
                len = size(df,1)-2
                #@show typeof(len)
                start_time, end_time = @cstatic start_time=Cint(1) end_time=Cint(2) begin
                    @c CImGui.SliderInt("Start Time", &start_time, 1,len)
                    CImGui.SameLine(0.0, CImGui.GetStyle().ItemInnerSpacing.x)
                    time1 = Dates.unix2datetime(st+ (start_time-1)/freq)
                    CImGui.Text(string(Time(time1)))
                    @c CImGui.SliderInt("End Time", &end_time, 2,len)
                    CImGui.SameLine(0.0, CImGui.GetStyle().ItemInnerSpacing.x)
                    time2 = Dates.unix2datetime(st+ (end_time-1)/freq)
                    CImGui.Text(string(Time(time2)))
                    if start_time > end_time -1
                        start_time = end_time - Cint(1)
                    elseif start_time < end_time - 2000*freq
                        start_time = end_time - Cint(2000*freq)
                    end
                    #if end_time < start_time + 1
                    #    end_time =  start_time + Cint(1)
                    #elseif end_time > start_time + 7000
                    #    end_time = start_time + Cint(7000)
                    #end

                end
                #@cstatic length = Cint(size(df, 1) - 2)
                #@show typeof(length)
                #@cstatic start_time = Cint(1) end_time = Cint(70) begin
                #    @c CImGui.SliderInt("Start Time", &start_time, 1, length)
                #    @c CImGui.SliderInt("End Time", &end_time, 1, length)
                #end
                #data = Cfloat.(df[3:end, 1])

                data = Cfloat.(df[(start_time+2):(end_time+2),1])
                CImGui.Text("Primitives")
                    sz, thickness, col = @cstatic sz=Cfloat(36.0) thickness=Cfloat(4.0) col=Cfloat[1.0,0.0,0.4,0.2] begin
                        CImGui.ColorEdit4("Color", col)
                    end
                    p = CImGui.GetCursorScreenPos()
                    col32 = CImGui.ColorConvertFloat4ToU32(ImVec4(col...))

                    begin
                        width = 1200
                        height = 200

                        CImGui.PlotLines("EDA Measurements", data, length(data), 0 , "EDA", 0, Cfloat(max_value*1.2), (width,height))
                        draw_list = CImGui.GetWindowDrawList()
                        x::Cfloat = p.x
                        y::Cfloat = p.y
                        spacing = 8.0
                        # Draws (almost transparent) horizontal bars
                        for yₙ in range(y, step = 40, stop = y + height - 40)
                            CImGui.AddRectFilled(draw_list, ImVec2(x, yₙ), ImVec2(x+width, yₙ+20), col32);
                        end
                    end

                    #draw the x axis
                    p = CImGui.GetCursorScreenPos()
                    begin
                        width = 1200
                        col = Cfloat[0.0,0.0,0.0,1.0]
                        col32 = CImGui.ColorConvertFloat4ToU32(ImVec4(col...))
                        draw_list = CImGui.GetWindowDrawList()
                        x = p.x
                        y = p.y
                        #CImGui.display(typeof(p))

                        time = Dates.unix2datetime(st+ (start_time-1)/freq)
                        f = Cfloat(1 / freq)
                        CImGui.AddLine(draw_list, ImVec2(x, y), ImVec2(x+width, y), col32, Cfloat(1));
                        for xₙ in range(x, step = 1200/ (end_time-start_time+1), stop = x + width)
                            hou = hour(time);
                            min = minute(time);
                            sec = second(time);
                            mil = millisecond(time);
                            if sec ==0 && mil ==0
                                CImGui.AddLine(draw_list, ImVec2(xₙ, y), ImVec2(xₙ, y-5), col32, Cfloat(1));
                            end
                            #if mil ==0
                            if sec ==0 && mil ==0
                                #CImGui.AddText(draw_list, ImVec2(xₙ, y), col32, string(string(min), ":", string(sec)));
                                CImGui.AddText(draw_list, ImVec2(xₙ, y), col32, string(string(hou), ":", string(min)));
                            end
                            next_time = time + Dates.Millisecond(f*1000);
                            time = next_time;
                        end
                    end


                    #date = Dates.unix2datetime(ts)

                    #day(date)
                    #month(date)
                    #year(date)
                    #hour(date)
                    #minute(date)
                    #second(date)
                    #millisecond(date)
                #x = range(0, stop = 2pi, length = 80)
                #f1(x) = sin.(x)
                #f2(x) = exp.(-x) .* cos.(2pi*x)
                #y1 = f1(x)
                #y2 = f2(x)

                #animate, _ = @cstatic animate=true arr=Cfloat[0.6, 0.1, 1.0, 0.5, 0.92, 0.1, 0.2] begin
                #    @c CImGui.Checkbox("Animate", &animate)
                #     data = view(df, 1)
                #     data = convert(Matrix, df)
                #     data = transpose(Matrix(df))
                #     data = convert(Array,data)
                #     CImGui.PlotLines("Result", data, length(data))

                    #@show typeof(data)
                    #@show typeof(Cfloat)
                #     convert(Matrix, df)
                    # create a dummy array of contiguous float values to plot
                    # Tip: If your float aren't contiguous but part of a structure, you can pass a pointer to your first float and the sizeof() of your structure in the Stride parameter.
                #    @cstatic values=fill(Cfloat(0),90) values_offset=Cint(0) refresh_time=Cdouble(0) begin
                #        (!animate || refresh_time == 0.0) && (refresh_time = CImGui.GetTime();)

                #        while refresh_time < CImGui.GetTime() # create dummy data at fixed 60 hz rate for the demo
                #            @cstatic phase=Cfloat(0) begin
                #                values[values_offset+1] = cos(phase)
                #                values_offset = (values_offset+1) % length(values)
                #                phase += 0.10*values_offset
                #                refresh_time += 1.0/60.0
                #            end
                #        end
                #        CImGui.PlotLines("Lines", values, length(values), values_offset, "avg 0.0", -1.0, 1.0, (0,80))
                #        CImGui.PlotHistogram("Histogram", arr, length(arr), 0, C_NULL, 0.0, 1.0, (0,80))
                #    end
                #end # @cstatic
                # use functions to generate output
                # FIXME: This is rather awkward because current plot API only pass in indices. We probably want an API passing floats and user provide sample rate/count.

                #CImGui.Text("")
                #Sin(::Ptr{Cvoid}, i::Cint) = Cfloat(sin(i * 0.1))
                #Saw(::Ptr{Cvoid}, i::Cint) = Cfloat((i & 1) != 0 ? 1.0 : -1.0)
                #Sin_ptr = @cfunction($Sin, Cfloat, (Ptr{Cvoid}, Cint))
                #Saw_ptr = @cfunction($Saw, Cfloat, (Ptr{Cvoid}, Cint))
                #@cstatic func_type=Cint(0) display_count=Cint(70) begin
                #    CImGui.Separator()
                #    CImGui.PushItemWidth(100)
                #    @c CImGui.Combo("func", &func_type, "Sin\0Saw\0")
                #    CImGui.PopItemWidth()
                #    CImGui.SameLine()
                #    @c CImGui.SliderInt("Sample count", &display_count, 1, 400)
                #    func = func_type == 0 ? Sin_ptr : Saw_ptr
                #    CImGui.PlotLines("Lines", func, C_NULL, display_count, 0, C_NULL, -1.0, 1.0, (0,80))
                #    CImGui.PlotHistogram("Histogram", func, C_NULL, display_count, 0, C_NULL, -1.0, 1.0, (0,80))
                #    CImGui.Separator()
                #end

                # animate a simple progress bar
                # @cstatic progress=Cfloat(0) progress_dir=Cfloat(1) begin
                    # if animate
                    #    progress += progress_dir * 0.4 * CImGui.GetIO().DeltaTime
                    #    progress ≥ 1.1 && (progress = 1.1; progress_dir *= -1.0;)
                    #    progress ≤ -0.1 && (progress = -0.1; progress_dir *= -1.0;)
                    # end

                    # typically we would use ImVec2(-1.0,0.0) to use all available width, or ImVec2(width,0.0) for a specified width. ImVec2(0.0,0.0) uses ItemWidth.
                    # CImGui.ProgressBar(progress, ImVec2(0.0,0.0))
                    # CImGui.SameLine(0.0, CImGui.GetStyle().ItemInnerSpacing.x)
                    # CImGui.Text("Progress Bar")

                    # progress_saturated = (progress < 0.0) ? 0.0 : (progress > 1.0) ? 1.0 : progress
                    # buf = @sprintf("%d/%d", progress_saturated*1753, 1753)
                    # CImGui.ProgressBar(progress, ImVec2(0,0), buf)
                # end
            end
            CImGui.End()
        end

        # show a simple window that we create ourselves.
        # we use a Begin/End pair to created a named window.
        # @cstatic f=Cfloat(0.0) counter=Cint(0) begin
        #    CImGui.Begin("Hello, world!")  # create a window called "Hello, world!" and append into it.
        #    CImGui.Text("This is some useful text.")  # display some text
        #    @c CImGui.Checkbox("Demo Window", &show_demo_window)  # edit bools storing our window open/close state
        #    @c CImGui.Checkbox("Another Window", &show_another_window)

        #    @c CImGui.SliderFloat("float", &f, 0, 1)  # edit 1 float using a slider from 0 to 1
        #    CImGui.ColorEdit3("clear color", clear_color)  # edit 3 floats representing a color
        #    CImGui.Button("Button") && (counter += 1)

        #    CImGui.SameLine()
        #    CImGui.Text("counter = $counter")
        #    CImGui.Text(@sprintf("Application average %.3f ms/frame (%.1f FPS)", 1000 / CImGui.GetIO().Framerate, CImGui.GetIO().Framerate))

        #    CImGui.End()
        # end

        # show another simple window.
        # if show_another_window
        #    @c CImGui.Begin("Another Window", &show_another_window)  # pass a pointer to our bool variable (the window will have a closing button that will clear the bool when clicked)
        #    CImGui.Text("Hello from another window!")
        #    CImGui.Button("Close Me") && (show_another_window = false;)
        #    CImGui.End()
        # end

        # rendering
        CImGui.Render()
        GLFW.MakeContextCurrent(window)
        display_w, display_h = GLFW.GetFramebufferSize(window)
        glViewport(0, 0, display_w, display_h)
        glClearColor(clear_color...)
        glClear(GL_COLOR_BUFFER_BIT)
        ImGui_ImplOpenGL3_RenderDrawData(CImGui.GetDrawData())

        GLFW.MakeContextCurrent(window)
        GLFW.SwapBuffers(window)
    end

    # cleanup
    ImGui_ImplOpenGL3_Shutdown()
    ImGui_ImplGlfw_Shutdown()
    CImGui.DestroyContext(ctx)

    GLFW.DestroyWindow(window)
end
