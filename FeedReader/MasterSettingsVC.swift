//
//  MasterSettingsVC.swift
//  FeedReader
//
//  Created by Mitchell Cooper on 2/21/15.
//  Copyright (c) 2015 Mitchell Cooper. All rights reserved.
//


import UIKit

class MasterSettingsVC: UITableViewController {
    
    convenience override init() {
        self.init(style: .grouped)
    }
    
    // MARK:- View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = Colors.tableColor
        tableView.separatorColor  = Colors.separatorColor
        tableView.rowHeight       = 60
        navigationItem.title      = "Settings"
    }
    
    // MARK:- Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    // number of rows in each section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return 2
        }
        
        // if background refresh is disabled, hide frequency cell
        return settings.backgroundRefresh ? 3 : 2
        
    }

    // only able to select license cell
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath == IndexPath(row: 1, section: 1)
    }
    
    // selected the license cell
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // only allow selection of license cell
        if indexPath != IndexPath(row: 1, section: 1) {
            return
        }
        
        let licenseVC = LicenseViewerVC(nibName: "LicenseViewerVC", bundle: nil)
        navigationController?.pushViewController(licenseVC, animated: true)
    }
    
    // header text
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 { return "Settings" }
        return "About"
    }
    
    // white header text
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        (view as! UITableViewHeaderFooterView).textLabel?.textColor = UIColor.white
    }
    
    // return a cell for a row
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // settings
        if indexPath.section == 0 {
            switch indexPath.row {
                case 0:  return daysToKeepCell()
                case 1:  return backgroundCheckCell()
                case 2:  return frequencyCell()
                default: break
            }
        }
        
        // about
        else {
            switch indexPath.row {
                
                // app version
                case 0:
                    let cell = genericCell()
                    cell.textLabel?.text = "Version"
                    cell.detailTextLabel?.text = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                    return cell
                
                // licenses
                case 1:
                    let cell = genericCell()
                    cell.accessoryType   = .disclosureIndicator
                    cell.textLabel?.text = "Licenses & Credits"
                    return cell
                
                default:
                    break
            }
        }
        return UITableViewCell()
    }
    
    // base cell
    fileprivate func genericCell() -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneric") as? UITableViewCell {
            cell.textLabel?.text        = ""
            cell.accessoryType          = .none
            cell.accessoryView          = nil
            cell.detailTextLabel?.text  = ""
            return cell
        }
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "settingsGeneric")
        cell.backgroundColor            = Colors.cellColor
        cell.selectedBackgroundView     = Colors.cellSelectedBackgroundView
        cell.textLabel?.textColor       = UIColor.white
        cell.detailTextLabel?.textColor = UIColor.white
        return cell
    }
    
    // MARK: Days to keep articles cell
    
    fileprivate weak var _daysLabel: UILabel?
    fileprivate func daysToKeepCell() -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.backgroundColor = Colors.cellColor
        
        // label
        cell.textLabel?.textColor = UIColor.white
        _daysLabel = cell.textLabel
        
        // stepper
        let stepper = UIStepper(frame: CGRect.zero) // frame is predefined
        stepper.backgroundColor = Colors.tableColor
        stepper.tintColor = Colors.accentColor
        stepper.layer.cornerRadius = 5
        stepper.addTarget(self, action: #selector(MasterSettingsVC.updateDays(_:)), for: .valueChanged)
        stepper.maximumValue = 1000
        stepper.minimumValue = 2
        stepper.value = Double(settings.daysToKeepArticles)
        updateDays(stepper)
        
        cell.accessoryView = stepper
        return cell
    }
    
    // stepper value changed
    func updateDays(_ stepper: UIStepper) {
        settings.daysToKeepArticles = Int(stepper.value)
        _daysLabel?.text = "Keep articles for \(settings.daysToKeepArticles) days"
    }
    
    // MARK: Background check enabled
    
    fileprivate func backgroundCheckCell() -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.backgroundColor = Colors.cellColor
        
        // label
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.text = "Update in background"
        
        // switch
        let switchCtrl = UISwitch()
        switchCtrl.tintColor      = Colors.accentColor
        switchCtrl.onTintColor    = Colors.accentColor
        switchCtrl.thumbTintColor = Colors.tableColor
        switchCtrl.addTarget(self, action: #selector(MasterSettingsVC.updateSwitch(_:)), for: .valueChanged)
        switchCtrl.isOn = settings.backgroundRefresh
        
        cell.accessoryView = switchCtrl
        return cell
    }
    
    // switch value changed
    func updateSwitch(_ switchCtrl: UISwitch) {
        let wasOn = settings.backgroundRefresh
        settings.backgroundRefresh = switchCtrl.isOn
        let path = IndexPath(row: 2, section: 0)
        
        // if it was on and now isn't, delete the frequency editor row
        if wasOn && !switchCtrl.isOn {
            tableView.deleteRows(at: [path], with: .automatic)
        }
            
        // if it was off and is now on, insert the frequency editor row
        else if !wasOn && switchCtrl.isOn {
            tableView.insertRows(at: [path], with: .automatic)
        }
        
        updateBackground()
    }
    
    // MARK: Background check frequency
    
    fileprivate weak var _freqLabel: UILabel?
    fileprivate func frequencyCell() -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.backgroundColor = Colors.cellColor
        
        // label
        cell.textLabel?.textColor = UIColor.white
        _freqLabel = cell.textLabel
        
        // stepper
        let stepper = UIStepper(frame: CGRect.zero) // frame is predefined
        stepper.backgroundColor = Colors.tableColor
        stepper.tintColor = Colors.accentColor
        stepper.layer.cornerRadius = 5
        stepper.addTarget(self, action: #selector(MasterSettingsVC.updateFrequency(_:)), for: .valueChanged)
        stepper.maximumValue = 1000
        stepper.minimumValue = 1
        stepper.value = Double(settings.backgroundFrequency)
        updateFrequency(stepper)
        
        cell.accessoryView = stepper
        return cell
    }
    
    // stepper value changed
    func updateFrequency(_ stepper: UIStepper) {
        settings.backgroundFrequency = Int(stepper.value)
        _freqLabel?.text = "Update every \(settings.backgroundFrequency) hours"
        updateBackground()
    }
    
    // update the registered refresh frequency 
    func updateBackground() {
        let freq = TimeInterval(3600 * settings.backgroundFrequency)
        UIApplication.shared.setMinimumBackgroundFetchInterval(settings.backgroundRefresh ? freq : UIApplicationBackgroundFetchIntervalNever)
    }
    
}

