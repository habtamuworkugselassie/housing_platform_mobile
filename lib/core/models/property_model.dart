class PropertyModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String location;
  final String imageUrl;
  final int bedrooms;
  final int bathrooms;
  final double area; // in sqft or sqm
  final String type; // e.g., 'House', 'Apartment'
  final bool isFeatured;
  final AgentModel agent;

  PropertyModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.location,
    required this.imageUrl,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.type,
    this.isFeatured = false,
    required this.agent,
  });

  // Mock Data factory
  static List<PropertyModel> get generateMockData {
    return [
      PropertyModel(
        id: '1',
        title: 'Modern Luxury Villa',
        description:
            'A beautiful modern villa with an infinity pool and stunning views of the surrounding mountains. Features a spacious open floor plan, high-end appliances, and beautifully landscaped gardens.',
        price: 2500000.0,
        location: 'Beverly Hills, CA',
        imageUrl:
            'https://images.unsplash.com/photo-1613977257363-707ba9348227?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        bedrooms: 4,
        bathrooms: 5,
        area: 4500.0,
        type: 'Villa',
        isFeatured: true,
        agent: AgentModel.mockAgent1,
      ),
      PropertyModel(
        id: '2',
        title: 'Downtown Skyline Penthouse',
        description:
            'Experience luxury living in the heart of the city. This penthouse offers panoramic skyline views, floor-to-ceiling windows, and access to premium building amenities including a gym and rooftop lounge.',
        price: 1850000.0,
        location: 'Downtown Core, NY',
        imageUrl:
            'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        bedrooms: 3,
        bathrooms: 3,
        area: 2100.0,
        type: 'Apartment',
        isFeatured: true,
        agent: AgentModel.mockAgent2,
      ),
      PropertyModel(
        id: '3',
        title: 'Cozy Suburban Family Home',
        description:
            'Perfect family home located in a quiet, tree-lined neighborhood. Features a large backyard, updated kitchen, and proximity to top-rated schools.',
        price: 850000.0,
        location: 'Oakridge Suburbs, TX',
        imageUrl:
            'https://images.unsplash.com/photo-1583608205776-bfd35f0d9f83?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        bedrooms: 3,
        bathrooms: 2,
        area: 1800.0,
        type: 'House',
        isFeatured: false,
        agent: AgentModel.mockAgent1,
      ),
      PropertyModel(
        id: '4',
        title: 'Minimalist Studio Loft',
        description:
            'Chic, industrial-style studio loft in the arts district. Exposed brick walls, high ceilings, and an open layout make this a perfect creative space.',
        price: 450000.0,
        location: 'Arts District, NY',
        imageUrl:
            'https://images.unsplash.com/photo-1554995207-c18c203602cb?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        bedrooms: 1,
        bathrooms: 1,
        area: 950.0,
        type: 'Apartment',
        isFeatured: false,
        agent: AgentModel.mockAgent2,
      ),
    ];
  }
}

class AgentModel {
  final String id;
  final String name;
  final String imageUrl;
  final String organization;
  final String phone;

  AgentModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.organization,
    required this.phone,
  });

  static AgentModel get mockAgent1 => AgentModel(
        id: 'a1',
        name: 'Sarah Jenkins',
        imageUrl:
            'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?ixlib=rb-4.0.3&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80',
        organization: 'Habte Real Estate',
        phone: '+1 (555) 123-4567',
      );

  static AgentModel get mockAgent2 => AgentModel(
        id: 'a2',
        name: 'Michael Chen',
        imageUrl:
            'https://images.unsplash.com/photo-1560250097-0b93528c311a?ixlib=rb-4.0.3&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80',
        organization: 'Habte Real Estate',
        phone: '+1 (555) 987-6543',
      );
}
