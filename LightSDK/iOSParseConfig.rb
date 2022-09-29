module LightConfigModule
    #没有指定配置文件时，加载默认配置，即LightAllFeatures全特性配置.路径和当前iOSParseConfig.rb同目录
    $config_json_file = "LightForQQZPlan.json"
    if ENV.key?("config_name") && ENV["config_name"] != ""
      puts "use costom json config"
      $config_json_file = ENV["config_name"]
    end
    path = __dir__ + "/" + $config_json_file
    config_json = File.read(path)
    $config_json_obj = JSON.parse(config_json)
    $config_json_obj.delete("version")

    puts "\n########################################################################################"
    puts "使用$config_json_obj[\"一级key\"][\"二级key\"]访问模块变量,用于控制文件、库是否参与编译、链接"
    puts "########################################################################################\n"
    #解析宏，调整被禁用的父级宏的子级宏为0
    $ios_pod_target_xcconfig = {}
    $ios_pod_target_xcconfig["GCC_PREPROCESSOR_DEFINITIONS"] = ['$(inherited)']
    level1 = $config_json_obj["ENABLE_COMPONENTS"]
    if level1 != nil
        puts "宏定义列表:"
        $config_json_obj["ENABLE_COMPONENTS"].each_pair() do |key,value|
            #使用配置的宏定义
            if value == "1"
                #定义一级宏
                puts ""
                puts "一级宏:#{key} = #{value}"
                $ios_pod_target_xcconfig["GCC_PREPROCESSOR_DEFINITIONS"] += ["#{key}=#{value}"]
                level2 = $config_json_obj["#{key}"]
                if level2 != nil
                    puts "#{key}下的二级宏"
                    level2.each_pair() do |key2,value2|
                        if value2 == "1"
                            puts  "#{key2} = #{value2}"
                            #定义二级宏
                            $ios_pod_target_xcconfig["GCC_PREPROCESSOR_DEFINITIONS"] += ["#{key2}=#{value2}"]
                            level3 = $config_json_obj["#{key2}"]
                            if level3 != nil
                                puts "#{key2}下的三级宏(玩法依赖的CV能力/基础能力)"
                                level3.each_pair() do |key3,value3|
                                    if value3 == "1"
                                        puts  "#{key3} = #{value3}"
                                        #定义三级宏
                                        $ios_pod_target_xcconfig["GCC_PREPROCESSOR_DEFINITIONS"] += ["#{key3}=#{value3}"]
                                    end
                                end
                            end
                        else
                            #二级宏被禁用，禁用该二级宏下面的三级宏
                            level3 = $config_json_obj["#{key2}"]
                            if level3 != nil
                                puts ""
                                level3.each_pair() do |key3,value3|
                                     puts "自动禁用三级宏 #{key2} -> #{key3}"
                                     $config_json_obj["#{key2}"]["#{key3}"] = "0"
                                end
                                puts ""
                            end
                        end
                    end
                end
            else
               level2 = $config_json_obj["#{key}"]
               if level2 != nil
                   level2.each_pair() do |key2,value2|
                        #一级宏被禁用，那么递归禁用该一级宏下面的二级宏，三级宏
                        puts ""
                        puts "自动禁用二级宏:#{key} -> #{key2}"
                        $config_json_obj["#{key}"]["#{key2}"] = "0"
                        level3 = $config_json_obj["#{key2}"]
                        if level3 != nil
                            level3.each_pair() do |key3,value3|
                                 puts "自动禁用三级宏:#{key2} -> #{key3}"
                                 $config_json_obj["#{key2}"]["#{key3}"] = "0"
                            end
                            puts ""
                        end
                   end
               end
            end
        end
    end
    #定义CV能力宏
    puts ""
    puts "CV启用能力列表(宏):"
    cvmap = $config_json_obj["ENABLE_CV"]
    if cvmap != nil
        cvmap.each_pair() do |key,value|
            #使用配置的宏定义
            if value == "1"
                puts ""
                puts  "#{key} = #{value}"
                $ios_pod_target_xcconfig["GCC_PREPROCESSOR_DEFINITIONS"] += ["#{key}=#{value}"]
                level2 = $config_json_obj["#{key}"]
                if level2 != nil
                    puts "#{key} CV能力二选一:"
                    level2.each_pair() do |key2,value2|
                        if value2 == "1"
                            puts  "#{key2} = #{value2}"
                            $ios_pod_target_xcconfig["GCC_PREPROCESSOR_DEFINITIONS"] += ["#{key2}=#{value2}"]
                        else
                            puts "自动禁用CV能力:#{key} -> #{key2}"
                            $config_json_obj["#{key}"]["#{key2}"] = "0"
                        end
                    end
                end
            else
               level2 = $config_json_obj["#{key}"]
               if level2 != nil
                   level2.each_pair() do |key2,value2|
                        #一级宏被禁用，那么递归禁用该一级宏下面的二级宏，三级宏
                        puts ""
                        puts "自动禁用CV能力:#{key} -> #{key2}"
                        $config_json_obj["#{key}"]["#{key2}"] = "0"
                   end
               end
            end
        end
    end
    puts ""

    def self.getJsonConfig
        return $config_json_obj
    end

    def self.getPodConfig
        return $ios_pod_target_xcconfig
    end

    def self.getConfigName
        return $config_json_file
    end
end
