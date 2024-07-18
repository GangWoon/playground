import SwiftUI

struct ColorItem: Identifiable, Equatable {
  let id: UUID = .init()
  var color: Color
  var imageName: String
  var colorName: String
  var hexColor: String
  var roundColor: String
  var description: String
}

extension [ColorItem] {
  static let preview: [ColorItem] = [
    ColorItem(
        color: Color.yellow,
        imageName: "eraser.line.dashed.fill",
        colorName: "Yellow",
        hexColor: "#FFFF00",
        roundColor: "#FFA500",
        description: "Yellow is often associated with sunshine, happiness, and energy. It is a bright and warm color that evokes feelings of cheerfulness and positivity. Yellow is known to stimulate mental activity and generate muscle energy. It is also considered to be an attention-grabbing color, often used in signs and advertisements due to its high visibility. The color yellow can create a sense of warmth and energy, making it popular in designs that aim to be inviting and lively. However, yellow can also have negative connotations. In some contexts, it is used to symbolize caution, such as in traffic signals and warning signs. It can also represent cowardice or deceit, as seen in the term 'yellow-bellied'. Despite these contrasting meanings, yellow remains a color that embodies warmth, enthusiasm, and optimism. It can bring a sense of joy and vibrancy wherever it is used, making it a powerful tool in design and communication. The dual nature of yellow, symbolizing both positivity and caution, gives it a unique place in the color spectrum, allowing it to be versatile in various applications."
    ),
    ColorItem(
        color: Color.blue,
        imageName: "pencil.tip.crop.circle",
        colorName: "Blue",
        hexColor: "#0000FF",
        roundColor: "#ADD8E6",
        description: "Blue is known for its calming and serene qualities. It is often associated with the sky and the sea, evoking a sense of tranquility and peace. Blue is believed to promote relaxation and reduce stress, making it a popular choice for bedrooms and bathrooms. It is also linked to trust, loyalty, and wisdom, often signifying reliability and competence in professional settings. The color blue can create a sense of calm and stability, which is why it is frequently used in corporate designs and logos. However, too much blue can sometimes be perceived as cold or distant, which is why it is often balanced with warmer colors in design. Blue also has a spiritual aspect, often associated with depth and introspection. In art and culture, it is used to represent melancholy and contemplation. Overall, blue represents calmness, stability, and reliability, creating a peaceful and stable environment. Its versatility allows it to be used effectively in a wide range of applications, from calming interiors to trustworthy corporate branding."
    ),
    ColorItem(
        color: Color.green,
        imageName: "square.and.pencil",
        colorName: "Green",
        hexColor: "#00FF00",
        roundColor: "#90EE90",
        description: "Green is commonly associated with nature, growth, and renewal. It is a soothing color that symbolizes harmony, freshness, and fertility. Green is often used to represent environmental and ecological initiatives due to its connection to the natural world. It signifies health, prosperity, and abundance. Psychologically, green is thought to relieve stress and aid in healing, making it a popular choice for spaces intended for relaxation and rejuvenation. The color green is also associated with safety and permission, as seen in green traffic lights and exit signs. However, it can also represent envy or inexperience in some contexts, as in the phrase 'green with envy' or 'greenhorn'. Despite these negative connotations, green remains a predominantly positive color, embodying balance, growth, and vitality. It fosters a sense of well-being and harmony, making it an ideal choice for a variety of settings, from calming interiors to vibrant marketing campaigns. The multifaceted nature of green, symbolizing both the vitality of life and the potential for growth, gives it a unique place in design and culture."
    ),
    ColorItem(
        color: Color.purple,
        imageName: "pencil.tip.crop.circle.badge.arrow.forward.fill",
        colorName: "Purple",
        hexColor: "#800080",
        roundColor: "#E6E6FA",
        description: "Purple is a color often associated with royalty, luxury, and ambition. It combines the stability of blue and the energy of red, resulting in a rich and dynamic color. Purple evokes creativity, mystery, and sophistication. Historically, it has been linked to nobility and spirituality, representing power and prestige. In modern contexts, purple can symbolize innovation and artistic expression. It is often used in design to create a sense of luxury and exclusivity. The color purple can inspire creativity and imagination, making it a popular choice for artistic and high-end brands. However, in some cultures, purple is also associated with mourning and sadness. Despite these associations, purple remains a powerful and versatile color. It symbolizes power, creativity, and depth, making it a color of complexity and richness. The dual nature of purple, representing both luxury and introspection, allows it to be used in a wide range of applications. Its ability to convey a sense of mystery and sophistication makes it a valuable tool in design and branding, appealing to both the imagination and the emotions."
    )
  ]
}
