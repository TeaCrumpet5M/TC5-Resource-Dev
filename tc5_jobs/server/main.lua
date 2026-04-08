exports('RegisterJob', function(jobDefinition)
    return TC5Jobs.RegisterJob(jobDefinition)
end)

exports('GetJobs', function()
    return TC5Jobs.GetJobs()
end)

exports('GetJobDefinition', function(jobName)
    return TC5Jobs.GetJobDefinition(jobName)
end)

exports('GetPlayerJob', function(src)
    return TC5Jobs.Server.GetPlayerJob(src)
end)

exports('SetPlayerJob', function(src, jobName, grade, onduty)
    return TC5Jobs.Server.SetPlayerJob(src, jobName, grade, onduty)
end)

exports('HasJob', function(src, jobName, minGrade)
    return TC5Jobs.Server.HasJob(src, jobName, minGrade)
end)

exports('ToggleDuty', function(src, state)
    return TC5Jobs.Server.ToggleDuty(src, state)
end)
