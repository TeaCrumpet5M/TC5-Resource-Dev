TC5Banking = TC5Banking or {}
TC5Banking.Config = {}

TC5Banking.Config.Debug = true
TC5Banking.Config.MaxPersonalAccounts = 3
TC5Banking.Config.StatementLimit = 60
TC5Banking.Config.AccountNumberPrefix = '52'
TC5Banking.Config.SortCode = '52-05-01'

TC5Banking.Config.OpenCommand = 'bank'
TC5Banking.Config.ATMCommand = 'atm'
TC5Banking.Config.MobileCommand = 'bankmobile'
TC5Banking.Config.CloseCommand = 'closebank'

TC5Banking.Config.BusinessCreationMinGrade = 3
TC5Banking.Config.EnableATMDeposits = true
TC5Banking.Config.EnableATMTransfers = true
TC5Banking.Config.UseInventoryCash = true
TC5Banking.Config.CashItemName = 'cash'

TC5Banking.Config.EnablePayroll = true
TC5Banking.Config.PayIntervalMinutes = 30
TC5Banking.Config.PayrollReference = 'Salary payment'
TC5Banking.Config.MaxInvoiceAmount = 500000
TC5Banking.Config.DefaultBusinessAccessGrade = 3

TC5Banking.Config.BankBranches = {
    { label = 'Downtown Bank', coords = vector3(149.89, -1040.74, 29.37) },
    { label = 'Hawick Bank', coords = vector3(314.19, -278.62, 54.17) },
    { label = 'Alta Bank', coords = vector3(-351.41, -49.67, 49.04) },
    { label = 'Great Ocean Bank', coords = vector3(-1212.87, -330.86, 37.79) }
}

TC5Banking.Config.ATMs = {
    vector3(147.61, -1035.75, 29.34),
    vector3(146.01, -1035.18, 29.34),
    vector3(-386.78, 6046.08, 31.50),
    vector3(-284.04, 6224.46, 31.49),
    vector3(-1109.80, -1690.79, 4.37),
    vector3(1171.52, 2702.57, 38.18),
    vector3(1686.84, 4815.82, 42.01),
    vector3(-95.56, 6457.16, 31.46)
}
