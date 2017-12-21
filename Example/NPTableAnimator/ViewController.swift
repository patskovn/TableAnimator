//
//  ViewController.swift
//  NPTableAnimator
//
//  Created by Nikita Patskov on 03/23/2017.
//  Copyright (c) 2017 Nikita Patskov. All rights reserved.
//

import UIKit
import NPTableAnimator


public func == (lhs: MySection, rhs: MySection) -> Bool {
	return lhs.id == rhs.id
}


public func == (lhs: MyCell, rhs: MyCell) -> Bool {
	return lhs.id == rhs.id
}


public struct MySection: TableAnimatorSection {
	
	public typealias Cell = MyCell
	
	public typealias UpdateCellType = Int
	
	
	public var hashValue: Int {
		return id.hashValue
	}
	
	let id: Int
	
	public var cells: [MyCell]
	
	public var updateField: Int {
		return 0
	}
	
	
	subscript(value: Int) -> MyCell {
		return cells[value]
	}
	
}




public struct MyCell: TableAnimatorCell {
	
	public typealias UpdateCellType = String
	
	let id: String
	
	public var hashValue: Int {
		return id.hashValue
	}
	
	public var updateField: String
	
}


public struct MySequenceIterator: IteratorProtocol {
	
	public typealias Element = MySection
	
	let sequence: MySequence
	
	init(sequence: MySequence) {
		self.sequence = sequence
	}
	
	mutating public func next() -> MySection? {
		
		let lastIndex = sequence.sections.count - 1
		var nextIndex = 0
		if (nextIndex > lastIndex) {
			return nil
		}
		let section = sequence.sections[nextIndex]
		nextIndex += 1
		return section
	}
	
}


public struct MySequence {
	
	typealias Iterator = MySequenceIterator
	
	/// Returns an iterator over the elements of this sequence.
	public func makeIterator() -> MySequenceIterator {
		return MySequenceIterator(sequence: self)
	}
	
	
	public typealias Section = MySection
	
	public var sections: [MySection]
	
	subscript(value: Int) -> MySection {
		return sections[value]
	}
}



class ViewController: UITableViewController {

	var currentList: MySequence! = nil
	
	let animator: TableAnimator<MySection> = {
		
		let config = TableAnimatorConfiguration<MySection>.init(cellMoveCalculatingStrategy: MoveCalculatingStrategy<MyCell>.top, sectionMoveCalculatingStrategy: MoveCalculatingStrategy<MySection>.bottom, isConsistencyValidationEnabled: true)
		let a = TableAnimator<MySection>.init(configuration: config)
		
		return a
	}()
	
	var animationCount = 0
	
	@IBAction func animate(_ sender: UIBarButtonItem) {
		
		let toList: MySequence
		
		if animationCount % 2 == 0 {
			toList = generateToList()
			
		} else {
			toList = generateFromList()
		}
		
		animationCount += 1
		
//		'attempt to perform an insert and a move to the same index path (<NSIndexPath: 0xc000000000000116> {length = 2, path = 1 - 0})'
		
		let animations = try! animator.buildAnimations(from: currentList.sections, to: toList.sections)
		
		tableView.apply(animations: animations,
						setNewListBlock: { [weak self] in
							if let strong = self {
								strong.currentList = toList
								return true
							} else {
								return false
							}
						},
						completion: nil,
						cancelBlock: nil,
						rowAnimation: .fade)
	}
	
	
	
	func generateFromList() -> MySequence {
//		let cells = [MyCell(id: "01b6151f-d113-2a1a-e17b-3117b1ad271a", updateField: "1513766375.251"), MyCell(id: "01461615-014f-7319-61cf-551671bcfb1e", updateField: "1513765277.575"), MyCell(id: "6144a9cc-85be-430e-91f9-02ba7875b99a", updateField: "1513761009.891"), MyCell(id: "01ca1615-01b0-731b-2144-9612e1958c19", updateField: "1513760850.515"), MyCell(id: "01431611-0139-7317-0114-8c165199f216", updateField: "1513760822.751"), MyCell(id: "3c6ad3db-7ed7-4d28-ac09-2fbc158287fe", updateField: "1513757906.778"), MyCell(id: "01d9161c-0120-721f-f1aa-5514911c4015", updateField: "1513757303.262"), MyCell(id: "c439e274-a28e-47fe-ab18-7f5b6caaf86d", updateField: "1513759397.366"), MyCell(id: "01691615-01f1-7214-e11e-ef1551a08414", updateField: "1513756789.611"), MyCell(id: "01ab1518-f1e4-d81f-4132-b71431996c1b", updateField: "1513756791.426"), MyCell(id: "01aa1610-016c-7212-e11f-9e12a1db2e1c", updateField: "1513756443.792"), MyCell(id: "01971613-014c-6917-0157-b913614f0b18", updateField: "1513756032.948"), MyCell(id: "01731611-0181-7218-b15e-8b1281c80711", updateField: "1513753540.683"), MyCell(id: "0111161a-0147-7219-b1a0-3013a1a6a918", updateField: "1513753648.081"), MyCell(id: "0133161e-01ab-721e-b1cb-2d19d165811e", updateField: "1513753646.2"), MyCell(id: "af64b1a8-f144-4e58-97e4-627643483727", updateField: "1513753643.751"), MyCell(id: "01421619-013b-6f1f-a157-0c1d61e91919", updateField: "1513752177.573"), MyCell(id: "017c1613-01cf-7211-a1ff-091d01da8417", updateField: "1513752175.253"), MyCell(id: "0166161d-0177-7213-71e4-6312a1b5e317", updateField: "1513752194.75"), MyCell(id: "012a1617-018a-7218-71eb-6a1bf1a7c513", updateField: "1513752195.705")]
//
		
		let cells = [MyCell.init(id: "1", updateField: "2")]
		
		let sections = MySection(id: 0, cells: cells)
		
		return MySequence(sections: [sections])
	}
	
	
	
	func test() {
		
	}
	
	
	func generateToList() -> MySequence {
		
//		let cells = [MyCell(id: "bf6280bd-adf6-4832-b4e3-8310e348ec99", updateField: "1513774668.087"), MyCell(id: "01e91615-01d3-7310-b1c1-e11881dd0c14", updateField: "1513774159.713"), MyCell(id: "01251617-0158-7319-9191-fc122174ec14", updateField: "1513769804.204"), MyCell(id: "01ab1518-f1e4-d81f-4132-b71431996c1b", updateField: "1513768147.448"), MyCell(id: "017f1614-013e-6d1d-5101-c5140182e11a", updateField: "1513768138.745"), MyCell(id: "01b6151f-d113-2a1a-e17b-3117b1ad271a", updateField: "1513767938.835"), MyCell(id: "01461615-014f-7319-61cf-551671bcfb1e", updateField: "1513765277.575"), MyCell(id: "6144a9cc-85be-430e-91f9-02ba7875b99a", updateField: "1513761009.891"), MyCell(id: "01ca1615-01b0-731b-2144-9612e1958c19", updateField: "1513760850.515"), MyCell(id: "01431611-0139-7317-0114-8c165199f216", updateField: "1513760822.751"), MyCell(id: "3c6ad3db-7ed7-4d28-ac09-2fbc158287fe", updateField: "1513757906.778"), MyCell(id: "01d9161c-0120-721f-f1aa-5514911c4015", updateField: "1513757303.262"), MyCell(id: "c439e274-a28e-47fe-ab18-7f5b6caaf86d", updateField: "1513759397.366"), MyCell(id: "01691615-01f1-7214-e11e-ef1551a08414", updateField: "1513756789.611"), MyCell(id: "01aa1610-016c-7212-e11f-9e12a1db2e1c", updateField: "1513756443.792"), MyCell(id: "01971613-014c-6917-0157-b913614f0b18", updateField: "1513756032.948"), MyCell(id: "01731611-0181-7218-b15e-8b1281c80711", updateField: "1513753540.683"), MyCell(id: "0111161a-0147-7219-b1a0-3013a1a6a918", updateField: "1513753648.081"), MyCell(id: "0133161e-01ab-721e-b1cb-2d19d165811e", updateField: "1513753646.2"), MyCell(id: "af64b1a8-f144-4e58-97e4-627643483727", updateField: "1513753643.751"), MyCell(id: "01421619-013b-6f1f-a157-0c1d61e91919", updateField: "1513752177.573"), MyCell(id: "017c1613-01cf-7211-a1ff-091d01da8417", updateField: "1513752175.253"), MyCell(id: "0166161d-0177-7213-71e4-6312a1b5e317", updateField: "1513752194.75"), MyCell(id: "012a1617-018a-7218-71eb-6a1bf1a7c513", updateField: "1513752195.705"), MyCell(id: "01bb161e-0177-7211-71d0-6d12611c9a1a", updateField: "1513752196.496"), MyCell(id: "016d1617-0166-721e-81e4-f51ea1d48015", updateField: "1513752197.18"), MyCell(id: "01fe161c-0134-6e1d-f12b-c51d518df116", updateField: "1513752652.53"), MyCell(id: "01fe1613-0103-6e13-91f8-471c31888417", updateField: "1513683835.798"), MyCell(id: "009408f8-3eb5-4730-9957-34f969a39cb5", updateField: "1513682427.783"), MyCell(id: "01a31616-0120-6e15-0132-6813311a4d1c", updateField: "1513682426.0"), MyCell(id: "4a5eca2f-a49a-46b1-a0af-2b988a9f96d4", updateField: "1513675393.229"), MyCell(id: "01801617-0198-6e13-0168-72153107da18", updateField: "1513674857.483"), MyCell(id: "01eb1616-0168-6e10-01f2-871031babf1b", updateField: "1513674844.815"), MyCell(id: "01aa1619-0143-6d11-01bb-ee175116d11f", updateField: "1513674688.664"), MyCell(id: "014e1614-0127-6e13-0159-6f19910f8312", updateField: "1513674721.268"), MyCell(id: "00fe6461-5563-473a-89bb-29e80c8768c4", updateField: "1513674986.619"), MyCell(id: "4e51ea4f-f868-4e9d-8b6c-702d8bee45e7", updateField: "1513674987.603"), MyCell(id: "01b5161b-018e-6d10-b10e-fb1ad176b01a", updateField: "1513670585.199"), MyCell(id: "88194771-f91c-4d13-b91d-568e063823f2", updateField: "1513666062.401"), MyCell(id: "3d18548b-8490-427a-a00f-6bfdc181ffee", updateField: "1513663803.537"), MyCell(id: "019b151f-f15d-a415-a158-8710810c6211", updateField: "1513663247.319"), MyCell(id: "3fea7635-0f8f-4b3b-b167-bb9b2e5d5e93", updateField: "1513659970.535"), MyCell(id: "55d76c15-0844-45e1-8d41-4cc245a94b48", updateField: "1513659868.054"), MyCell(id: "1c987660-3e9d-408f-bf11-8c580138c78d", updateField: "1513601910.854"), MyCell(id: "017a161d-014e-691f-71ba-0a1e21c71f1b", updateField: "1513774930.017"), MyCell(id: "01381611-0173-6916-31fa-681c515b0a19", updateField: "1513596225.224"), MyCell(id: "01ad1619-01c1-691d-31e6-1e1081cb8816", updateField: "1513594370.461"), MyCell(id: "01071614-0125-6916-21fa-3b1f817b6f1a", updateField: "1513593035.905"), MyCell(id: "018a1613-018a-6912-21e3-a119a120b71a", updateField: "1513593992.536"), MyCell(id: "01221616-014c-6814-d1dc-8d17b1c13116", updateField: "1513587579.064"), MyCell(id: "01c21615-01f6-6814-310d-091a41faf519", updateField: "1513578126.469"), MyCell(id: "21642043-af66-4118-a40a-3035c5b6d8ad", updateField: "1513576958.211"), MyCell(id: "01e01615-01aa-681a-1184-321c91b2c910", updateField: "1513576480.754"), MyCell(id: "36b99a26-ba62-41a8-a0d1-b485a93090ea", updateField: "1513573362.993"), MyCell(id: "01d91616-0165-5a1e-31cf-ed1401cbf213", updateField: "1513569031.979"), MyCell(id: "01c31610-01b4-591f-f17a-511c2189bb13", updateField: "1513339294.34"), MyCell(id: "01a11611-0191-591f-9108-2e1cd1a0b213", updateField: "1513332955.435"), MyCell(id: "01f71614-01e3-5915-8124-bc1241ed3e15", updateField: "1513333021.046"), MyCell(id: "013e1618-01df-5911-8148-c11d51250015", updateField: "1513333016.865"), MyCell(id: "01021615-0198-5911-8175-b11921240e1a", updateField: "1513330824.879"), MyCell(id: "01e1161c-0181-591e-8104-ac15c1eda312", updateField: "1513330825.548"), MyCell(id: "0177161c-0193-5919-41ed-7611b177ec13", updateField: "1513328827.753"), MyCell(id: "01571612-0159-5418-7109-6c1a51cb431a", updateField: "1513323659.929"), MyCell(id: "01751619-01b1-5515-11df-5d1821cf8410", updateField: "1513321631.529"), MyCell(id: "01bb1616-01f6-581a-f182-221de1fd141a", updateField: "1513320889.74"), MyCell(id: "48189cb2-4179-441d-b21d-e08bb52aa70e", updateField: "1513313068.973"), MyCell(id: "01e51616-01ec-571b-f1b1-ff14e1cad219", updateField: "1513312304.91"), MyCell(id: "01e8161c-01cb-5312-51cf-1a1411996919", updateField: "1513312224.959"), MyCell(id: "01451611-0135-541d-c146-491cb1dc621f", updateField: "1513255362.536"), MyCell(id: "01c9161b-0113-5419-b1de-111dc1dd4f1c", updateField: "1513255938.187"), MyCell(id: "01491614-0137-5415-517b-9e1341d58b11", updateField: "1513243684.637"), MyCell(id: "7d6691b5-9bf0-4d10-816b-67ee38b383cf", updateField: "1513238865.6"), MyCell(id: "01071613-0108-5318-b199-b51481af2f1b", updateField: "1513238506.234"), MyCell(id: "95385d2e-e3fd-4540-abde-7ec3ef98630a", updateField: "1513233349.591"), MyCell(id: "017c1617-010b-5319-b1cb-3d166190a913", updateField: "1513233029.246"), MyCell(id: "a382cc8a-3fd6-42a7-800a-bcfea570b5a8", updateField: "1513243191.952"), MyCell(id: "01fe161e-0173-491d-4165-3e11f1945f15", updateField: "1513228303.13"), MyCell(id: "014b161b-01ce-341a-f19f-9218116a361c", updateField: "1513166337.513"), MyCell(id: "d2b386f8-c385-45e9-ae8f-5f861bea6250", updateField: "1513161498.368"), MyCell(id: "215e6dd3-d295-4b32-be88-9cb1c57d85fb", updateField: "1513153498.102"), MyCell(id: "01311614-01f8-4e1c-f131-4c1341ace91b", updateField: "1513153277.102"), MyCell(id: "01491616-0133-4e1c-b149-1319e1f6071c", updateField: "1513150552.83"), MyCell(id: "01cb161b-0149-4a1f-c138-791121653015", updateField: "1513226587.385"), MyCell(id: "01841519-f122-a019-41a9-171db192a714", updateField: "1513138297.834"), MyCell(id: "e811973d-3bbf-41c3-ba0c-f306e5e6bbd1", updateField: "1513078310.038"), MyCell(id: "5596f124-c41c-419b-8a55-8d30ec832f81", updateField: "1513073735.446"), MyCell(id: "01f91614-01cc-4a12-11c0-d1103148ca1c", updateField: "1513073205.449"), MyCell(id: "012f1617-01b6-491b-b186-ca18f1eeae18", updateField: "1513066173.614"), MyCell(id: "61d893bd-c23c-42e6-8536-9ccf1c6ebb0f", updateField: "1513059121.078"), MyCell(id: "01161613-01e2-4911-510f-121881df731c", updateField: "1513058634.955"), MyCell(id: "0185161c-01f3-4515-4124-2b1d71747110", updateField: "1513053064.583"), MyCell(id: "8b682b1d-7561-4665-84c9-50d8682c055b", updateField: "1512996044.11"), MyCell(id: "01b21611-0145-4511-71f2-1c14e13ac21a", updateField: "1512994959.493"), MyCell(id: "01d01618-01a0-4512-21b2-3e1ca1c44719", updateField: "1512989037.636"), MyCell(id: "c225f59e-dba5-471a-867e-cc63ff127d7b", updateField: "1512988569.818"), MyCell(id: "44ead7fa-be28-456d-9354-a9a02641383e", updateField: "1512986758.257"), MyCell(id: "011c151a-f1d8-de1b-21ba-4d1eb17ce11a", updateField: "1512740056.902"), MyCell(id: "017a1619-01a6-361d-4138-741fe1a5d31d", updateField: "1512740059.486"), MyCell(id: "4805c316-adc7-43d7-8d76-01cbb127e3cc", updateField: "1512732318.319"), MyCell(id: "01d41616-01f7-351e-61f9-5b1db1b3f614", updateField: "1512724354.954"), MyCell(id: "01761612-0154-3512-2144-941ad18a0410", updateField: "1512721548.355"), MyCell(id: "8e5bccad-21b5-4e82-93a2-8a219db6181f", updateField: "1512710979.751"), MyCell(id: "85b2303d-eb75-4459-a221-c27184506665", updateField: "1512711148.427"), MyCell(id: "01d21612-01bd-3118-6112-5f14f1eafc1a", updateField: "1512711149.897"), MyCell(id: "f557d8ff-0097-4a2c-a901-0e63bd49f6cc", updateField: "1512649908.115"), MyCell(id: "017c1612-010e-3014-413a-0812f15bf61a", updateField: "1512650689.975"), MyCell(id: "01a7161d-0148-2c1b-319d-351bb1cb7b10", updateField: "1512633878.662"), MyCell(id: "019c1617-014c-2c1d-3167-c31851460917", updateField: "1512632538.325"), MyCell(id: "01cf1611-01db-2f1b-d155-251db12c8716", updateField: "1512630940.586"), MyCell(id: "2413ca01-36c7-4025-9681-458659d11ca8", updateField: "1512629449.799"), MyCell(id: "3d65adab-7be3-426d-9211-87b71317d58e", updateField: "1512627877.852"), MyCell(id: "f1ca27b4-c909-476a-bce4-8f7e03a7089c", updateField: "1512626202.733"), MyCell(id: "d97703d7-2b47-46a5-bcb0-63b090896797", updateField: "1512626427.197"), MyCell(id: "01ee1618-0193-2f16-4143-d21a4129b210", updateField: "1512622669.773"), MyCell(id: "75c142f9-0a6f-4d4b-b038-4f9fee893bd0", updateField: "1512563716.958"), MyCell(id: "87185aa5-4c62-4230-a06f-8abd8373afb9", updateField: "1512561082.343"), MyCell(id: "01f6161b-017b-2b1c-9105-d21731b5a319", updateField: "1512561094.705"), MyCell(id: "011b161b-012a-2b1d-51b9-611191027f15", updateField: "1512560047.037"), MyCell(id: "0127161d-0134-2b11-81a7-4618d1f7f318", updateField: "1512559621.02"), MyCell(id: "016d1611-0134-2b10-618b-0216c1a0d51f", updateField: "1512557154.226"), MyCell(id: "01641619-01a7-2b1f-31f7-f11e414dcf11", updateField: "1512556009.254"), MyCell(id: "ff473763-cb55-4393-a6bf-0acb64bee24a", updateField: "1512553680.413"), MyCell(id: "01581611-015f-2b1b-010c-0f1491393517", updateField: "1512552279.21"), MyCell(id: "cec86c75-2230-4357-99fa-c53f651fdff7", updateField: "1512548218.973"), MyCell(id: "047b787c-7435-481d-95fe-49d7b1bdd84f", updateField: "1512547877.664"), MyCell(id: "013f1614-01ca-291d-e104-be13b14bf210", updateField: "1512532309.649"), MyCell(id: "8f292104-fefd-4601-bfc0-6ef2257b0cfd", updateField: "1512531073.735"), MyCell(id: "9d20b476-e0f2-4fc6-aad2-8d351778a5d4", updateField: "1512527625.214"), MyCell(id: "8101ff45-a28d-4383-bd50-bd565b542666", updateField: "1512473580.225"), MyCell(id: "01391613-012c-2615-41c5-6c1ba1470b1e", updateField: "1512470734.862"), MyCell(id: "01f11616-011d-261a-1134-6f1c91f84115", updateField: "1512467782.077"), MyCell(id: "01b71618-0116-261f-1166-3d1d01e1fa1d", updateField: "1512467671.287"), MyCell(id: "01401612-0181-2617-11af-221a410f1915", updateField: "1512469907.595"), MyCell(id: "58d650f2-a8c8-4d17-9462-f154dcfe0422", updateField: "1512467798.992"), MyCell(id: "0490fa0f-0ace-420a-b757-c7f2ac69d884", updateField: "1512466466.067"), MyCell(id: "b926fc6d-a574-4ee3-ac1c-6c6b70d88e43", updateField: "1512465278.486"), MyCell(id: "508237f4-5715-4c44-bf76-48018107fc72", updateField: "1512461077.854"), MyCell(id: "81901265-c468-4d07-81d0-e071e73a9923", updateField: "1512459624.436"), MyCell(id: "01671613-0138-2016-e16b-561941a2c113", updateField: "1512396740.124"), MyCell(id: "ee6c9d63-74ee-4706-aed5-9332e69377f2", updateField: "1512375327.882"), MyCell(id: "016a161d-0159-201b-615f-541ff1c62f1d", updateField: "1512372326.189"), MyCell(id: "018d1610-0103-2015-319d-871821207f1e", updateField: "1512371263.229"), MyCell(id: "01611614-01b4-121f-c15a-af18f15ef71f", updateField: "1512979131.248"), MyCell(id: "018f161d-011a-1118-f1c8-131ac16b7614", updateField: "1512130667.424"), MyCell(id: "612fcbea-3b3f-4b06-8ab0-131bad9c487d", updateField: "1512123396.857"), MyCell(id: "0141161e-010f-111a-5109-861a311da419", updateField: "1512119564.968"), MyCell(id: "4f45887a-04c7-4f78-abd6-70975f687603", updateField: "1512118133.245"), MyCell(id: "01731612-01f2-0d1e-818a-3519f191b118", updateField: "1512118322.483"), MyCell(id: "4c4a43de-65ce-4982-b924-584532d4e01d", updateField: "1512115990.924"), MyCell(id: "83103e02-4c4e-4e9a-baf6-c0d9f13715a2", updateField: "1512115118.322"), MyCell(id: "01bc1613-0173-101f-c15c-ce1791a03d19", updateField: "1512116977.374"), MyCell(id: "011b1612-0163-0e1c-f1cc-d91f71c0eb1d", updateField: "1512102887.94"), MyCell(id: "01a81615-014e-0c18-e161-db14519b8f14", updateField: "1512046422.921"), MyCell(id: "01131618-013d-0c13-e172-891361f40a12", updateField: "1512046006.112"), MyCell(id: "010f1618-01f0-0c14-e1d0-831af176801c", updateField: "1512046004.712"), MyCell(id: "01c51619-016f-0c13-a1c6-201f5119a514", updateField: "1512044989.894"), MyCell(id: "0166161e-017d-071e-d184-e71091248712", updateField: "1512040012.444"), MyCell(id: "b277e253-42ab-481a-b3bf-7d3b31925544", updateField: "1512036094.424"), MyCell(id: "01f11613-0167-0b12-91b3-9b1161123613", updateField: "1512034775.243"), MyCell(id: "01511611-01a4-0b19-a1f2-9710f12c9c14", updateField: "1512031015.041"), MyCell(id: "5afb46e5-2cca-4b32-b365-f77ffe1723b5", updateField: "1512029761.144"), MyCell(id: "01701618-0107-0b1d-214f-de16c176b41d", updateField: "1512023446.649"), MyCell(id: "011b1613-01b6-0b13-2167-af18f1984018", updateField: "1512015931.199"), MyCell(id: "01091610-01ca-0710-510c-f41031b9ed15", updateField: "1511955219.468"), MyCell(id: "e5ec7df2-ae43-4545-8cc9-af653219e471", updateField: "1511953947.619"), MyCell(id: "01501618-0164-071c-61ad-df1831c5f117", updateField: "1511958702.397"), MyCell(id: "755782ad-5b91-4b5e-8920-9d4287fc1a23", updateField: "1511952822.712"), MyCell(id: "01a31617-0113-0714-11ea-7f1c511e1d1c", updateField: "1511951994.352"), MyCell(id: "01f1161f-01e5-061f-71cd-c01fb1cca01d", updateField: "1511945274.372"), MyCell(id: "01e21610-011c-021b-b1fa-701a2162ec1e", updateField: "1511937369.159"), MyCell(id: "017c1611-01fb-0619-71ab-9116f1a15a11", updateField: "1511937153.458"), MyCell(id: "01bb1616-01ab-021a-c147-5f1d6148d317", updateField: "1511936656.863"), MyCell(id: "0186161a-0125-011c-115c-7714217afd1c", updateField: "1511850061.116"), MyCell(id: "017b1510-f1c4-fc10-d134-041f81dda412", updateField: "1511775164.308"), MyCell(id: "01f11518-f1a7-fc17-d13d-0d131197c517", updateField: "1511775163.429"), MyCell(id: "395691f8-0300-4da7-8ada-ced13358c1c9", updateField: "1511775094.337"), MyCell(id: "01851516-f1d4-fc15-41f2-041b31d27315", updateField: "1511766340.231"), MyCell(id: "01691515-f1e6-fb19-b137-e91d51b19d15", updateField: "1511757891.6"), MyCell(id: "0136151f-f1a8-fb1a-b14c-4611e1102613", updateField: "1511756552.839"), MyCell(id: "01b31519-f1b6-dc1d-f174-e814f18b171f", updateField: "1511752697.793"), MyCell(id: "eea830fa-f4b7-4e1c-b94c-0e8c06afe1b1", updateField: "1511432864.352"), MyCell(id: "019d1511-f198-e318-919a-2b191195b31e", updateField: "1511360528.835"), MyCell(id: "f9dd7bc9-0bcd-48b4-a601-a7ad6b7afa66", updateField: "1511342736.185"), MyCell(id: "0129151d-f162-e21f-e1d9-69136187af16", updateField: "1511340507.036"), MyCell(id: "01d31510-f1d2-e214-e17d-0b15f186e91c", updateField: "1511340895.913"), MyCell(id: "01841517-f110-d913-c123-28147112ae10", updateField: "1511246933.297"), MyCell(id: "8f9fecd7-4ef5-4185-a909-b9306c8e8655", updateField: "1511183795.424"), MyCell(id: "01221515-f1e0-c416-712c-7b1fa198fc1a", updateField: "1511158395.98"), MyCell(id: "01e2151c-f125-c816-c1a3-201621cd2b14", updateField: "1510902625.788"), MyCell(id: "01781515-f134-c411-d1cf-2912b1abc11d", updateField: "1510905786.954"), MyCell(id: "3ed75508-f013-4f51-adc9-ac7324176a05", updateField: "1510821738.19"), MyCell(id: "5177c774-b791-42cb-9bd0-30cfdb38b4d8", updateField: "1510751591.282"), MyCell(id: "9cfd213a-b3a2-4c8f-8086-f2d443f2eb38", updateField: "1510733073.607"), MyCell(id: "01f61513-f127-b91b-c141-5711a1d2741f", updateField: "1510659262.773"), MyCell(id: "01eb1514-f1f2-a61d-017f-441f3122b917", updateField: "1510557070.709"), MyCell(id: "010c151b-f11c-a01b-413d-791f81017717", updateField: "1510228886.08"), MyCell(id: "016c1517-f170-5812-8176-bc1f81a10a16", updateField: "1509025765.918"), MyCell(id: "014b151a-f136-5214-f174-4f1c51310f1a", updateField: "1508933042.834"), MyCell(id: "08758d88-e3f6-4015-95a2-68a0d56e3fe9", updateField: "1508829008.686"), MyCell(id: "01321512-f1d5-3813-2178-5a19f158671e", updateField: "1508497434.919"), MyCell(id: "01301512-f16b-3817-8107-1d1ee11a5319", updateField: "1508481744.398"), MyCell(id: "0125151e-f1e7-151f-f134-1d1c01447c11", updateField: "1508326035.717"), MyCell(id: "452b0ce8-0749-4187-8dd8-b0529f8ee72a", updateField: "1508306924.602"), MyCell(id: "7f4b43a7-fc31-474a-bd62-201ad2cfd9fd", updateField: "1507875347.844"), MyCell(id: "01fb151c-f1af-0e16-d125-1a1ba16e3d12", updateField: "1507802418.143"), MyCell(id: "01651516-e1e0-f016-810b-9c1e2100031b", updateField: "1507278046.984"), MyCell(id: "01ab1510-e1ec-cd18-817a-011f01fcf013", updateField: "1506690029.3"), MyCell(id: "01501515-e19a-cc16-e1ec-4b1a813f7f10", updateField: "1506676428.863"), MyCell(id: "016c1515-e165-c31f-61d0-221cd1661f10", updateField: "1506676423.279"), MyCell(id: "01421516-e1ef-be1b-d150-cb1ef1909b1d", updateField: "1506495308.759"), MyCell(id: "01ca1516-e1e4-b815-a10e-4d1351bc9112", updateField: "1506337556.887"), MyCell(id: "01cb1517-e156-b714-c1ff-d81991762e10", updateField: "1506332451.294"), MyCell(id: "0e7d50a8-884d-4385-9f7d-0406cc6e6a97", updateField: "1506329434.025"), MyCell(id: "07ac0467-1f2e-4d9a-82e1-5591a706d639", updateField: "1505996448.051"), MyCell(id: "215ba9a4-9c61-44a8-9696-e6df9d273805", updateField: "1505885783.468"), MyCell(id: "01311516-e1c2-5013-614b-b015710d131d", updateField: "1505361417.111"), MyCell(id: "01a51514-e144-7617-1162-1414111ebf18", updateField: "1505670027.255"), MyCell(id: "ed6f9ea7-d5f6-416d-8852-426bad3f19c1", updateField: "1505214895.202"), MyCell(id: "012f1510-e16d-3814-a13a-ad14b1698e12", updateField: "1505202799.44"), MyCell(id: "01bb1519-e1cf-5c19-71fb-851361641311", updateField: "1504793222.201"), MyCell(id: "01fa1517-e172-5018-a19e-d61481b18c1f", updateField: "1504612467.418"), MyCell(id: "011f1516-e146-5113-01d6-491741b34f1a", updateField: "1504783783.172"), MyCell(id: "851c65d9-c696-4835-80bb-c2ca6b0cffc8", updateField: "1508140478.468"), MyCell(id: "012d1514-e10f-4b18-b130-6615718e4017", updateField: "1504783809.11"), MyCell(id: "015d151a-e1fd-4b1d-213e-b216c1e2731b", updateField: "1504515678.922"), MyCell(id: "01111512-e1cc-3c1b-d16a-211aa171e21b", updateField: "1504512517.963"), MyCell(id: "0167151a-e1c1-3719-f135-fd1d11dfe718", updateField: "1504187416.622"), MyCell(id: "de9ec066-5431-4952-989d-90b06c69e3a9", updateField: "1504173174.736"), MyCell(id: "01041518-e13b-371f-112a-9512415c7d1b", updateField: "1504166246.994"), MyCell(id: "01701514-e157-361d-c133-531b917aeb13", updateField: "1504163685.247"), MyCell(id: "01481512-d192-a314-1105-411691c3fa13", updateField: "1502798511.538"), MyCell(id: "01971519-d166-5f18-8191-6a16e1956c17", updateField: "1502450602.434"), MyCell(id: "01071518-d1ae-1c12-9167-8e16c172691e", updateField: "1499752230.331"), MyCell(id: "ec23a160-6ee0-4127-a4d8-6075c91cd4d3", updateField: "1497617745.316"), MyCell(id: "01e8151b-c1df-a519-c1e2-8b1cb1331412", updateField: "1497504929.735")]

		
		let cells = [MyCell.init(id: "1", updateField: "3")]
		
		let sections = MySection(id: 0, cells: cells)
		
		return MySequence(sections: [sections])
	}
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		currentList = generateFromList()
		
    }

	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return currentList.sections.count
	}
	
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return currentList.sections[section].cells.count
	}
	
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = UITableViewCell()
		
		cell.textLabel?.text = String(currentList[indexPath.section].cells[indexPath.row].id)
		
		return cell
	}

}









