//
//  GroupEditorVC.swift
//  FeedReader
//
//  Created by Mitchell Cooper on 2/20/15.
//  Copyright (c) 2015 Mitchell Cooper. All rights reserved.
//

import UIKit

class GroupEditorVC: UITableViewController, UITextFieldDelegate {
    weak var group: FeedGroup!
    
    convenience init(group: FeedGroup) {
        self.init(style: .grouped)
        self.group = group
    }
    
    // MARK:- View controller

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "GroupCell", bundle: nil), forCellReuseIdentifier: "group")
        tableView.backgroundColor = Colors.tableColor
        tableView.separatorColor  = Colors.separatorColor
        navigationItem.title      = "\(group.title.capitalized) settings"
    }

    // MARK:- Table view data source

    // number of sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    // numbers of rows in each section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : 4
    }

    // all rows 60 except for preview
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 0 ? 100 : 60
    }
    
    // only able to select change icon cell
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath == IndexPath(row: 3, section: 1)
    }
    
    // selected change icon cell
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // only allow selection of change icon
        if indexPath != IndexPath(row: 3, section: 1) {
            return
        }
        
        let iconVC = GroupIconChooserVC(group: group)
        navigationController?.pushViewController(iconVC, animated: true)
    }
    
    // section titles
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 { return "Preview" }
        return "Settings"
    }
    
    // white header text
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        (view as! UITableViewHeaderFooterView).textLabel?.textColor = UIColor.white
    }
    
    // return a cell for a row
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return previewCell()
        }
        switch indexPath.row {
            case 0:  return groupNameCell()
            case 1:  return stepperCell()
            case 2:  return automaticallyFetchCell()
            case 3:  return changeIconCell()
            default: return UITableViewCell()
        }
    }
    
    // MARK: Preview cell
    
    fileprivate func previewCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "group") as! GroupCell
        cell.setGroup(group)
        return cell
    }
    
    // MARK: Group name cell
    
    fileprivate func groupNameCell() -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.backgroundColor = Colors.cellColor
        
        // label
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.text = "Group name"
        
        // text field
        let textField = UITextField(frame: CGRect(x: 0, y: 0, width: 175, height: 30))
        textField.keyboardAppearance = .dark
        textField.backgroundColor = UIColor.clear
        textField.returnKeyType = .done
        textField.textAlignment = .right
        textField.textColor = UIColor.white
        textField.text = group.userSetTitle
        textField.delegate = self
        textField.attributedPlaceholder = NSAttributedString(string: "Unnamed", attributes: [ NSForegroundColorAttributeName: UIColor.lightGray ])
        textField.addTarget(self, action: #selector(GroupEditorVC.updateTitle(_:)), for: .editingChanged)

        cell.accessoryView = textField
        return cell
    }
    
    // title changed
    func updateTitle(_ textField: UITextField) {
        group.userSetTitle   = textField.text!
        navigationItem.title = "\(group.title.capitalized) settings"
    }
    
    // Text field delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        updateTitle(textField)
        textField.resignFirstResponder()
        return false
    }
    
    // MARK: Stepper cell
    
    fileprivate weak var _daysLabel: UILabel?
    fileprivate func stepperCell() -> UITableViewCell {
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
        stepper.addTarget(self, action: #selector(GroupEditorVC.updateStepper(_:)), for: .valueChanged)
        stepper.maximumValue = 1000
        stepper.minimumValue = 2
        stepper.value = Double(group.daysToKeepArticles)
        updateStepper(stepper)

        cell.accessoryView = stepper
        return cell
    }
    
    // stepper value changed
    func updateStepper(_ stepper: UIStepper) {
        group.daysToKeepArticles = Int(stepper.value)
        _daysLabel?.text = "Keep articles for \(group.daysToKeepArticles) days"
    }
    
    // MARK: Automatically fetch cell
    
    fileprivate func automaticallyFetchCell() -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.backgroundColor = Colors.cellColor
        
        // label
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.text = "Refresh automatically"
        
        // switch
        let switchCtrl = UISwitch()
        switchCtrl.tintColor      = Colors.accentColor
        switchCtrl.onTintColor    = Colors.accentColor
        switchCtrl.thumbTintColor = Colors.tableColor
        switchCtrl.addTarget(self, action: #selector(GroupEditorVC.updateSwitch(_:)), for: .valueChanged)
        switchCtrl.isOn = group.automaticRefresh
        
        cell.accessoryView = switchCtrl
        return cell
    }
    
    // switch value changed
    func updateSwitch(_ switchCtrl: UISwitch) {
        group.automaticRefresh = switchCtrl.isOn
    }
    
    // MARK: Change icon cell
    fileprivate func changeIconCell() -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.backgroundColor = Colors.cellColor
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.text = "Change group icon"
        cell.accessoryType = .disclosureIndicator
        cell.selectedBackgroundView = Colors.cellSelectedBackgroundView
        return cell
    }
    
}

// MARK:- Icon chooser

class GroupIconChooserVC: UITableViewController {
    weak var group: FeedGroup!
    
    // find the icons
    let files = FileManager.default.contentsOfDirectoryAtPath(Bundle.mainBundle().resourcePath! + "/icons/group", error: nil) as [String]!
    
    convenience init(group: FeedGroup) {
        self.init(style: .plain)
        self.group = group
    }
    
    // MARK: View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = Colors.tableColor
        tableView.separatorColor  = Colors.separatorColor
        tableView.rowHeight       = 60
        navigationItem.title      = "Choose icon"
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(GroupIconChooserVC.cancelButtonTapped(_:)))
    }
    
    // MARK: Table view data source
    
    // just one section
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // number of rows
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    // return a cell for a row
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let fileName = files[indexPath.row]
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.text  = fileName.stringByDeletingPathExtension
        cell.textLabel?.font  = UIFont.systemFont(ofSize: 20)
        cell.imageView?.image = UIImage(named: "icons/group/\(fileName)")
        cell.backgroundColor  = Colors.cellColor
        cell.selectedBackgroundView = Colors.cellSelectedBackgroundView
        return cell
    }
    
    // selected an icon
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fileName = files[indexPath.row]
        group.icon = UIImage(named: "icons/group/\(fileName)")
        group.iconResource = fileName
        rss.center.post(name: Notification.Name(rawValue: FeedGroup.Notifications.AppearanceChanged), object: group)
        navigationController?.popViewController(animated: true)
    }
    
    // cancel button tapped
    func cancelButtonTapped(_: AnyObject) {
        navigationController?.popViewController(animated: true)
    }
    
}
