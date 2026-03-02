# https://api.iqfluence.io/v2.0/api/search/newv1/


## Request
{
  "filter": {
    "audience_age": [
      {
        "code": "18-24",
        "weight": 0.25
      }
    ],
    "audience_age_range": {
      "left_number": "string",
      "right_number": "string",
      "weight": 0.25,
      "operator": "lt"
    },
    "audience_brand": [
      {
        "id": 0,
        "weight": 0.1
      }
    ],
    "audience_brand_category": [
      {
        "id": 0,
        "weight": 0.1
      }
    ],
    "audience_gender": {
      "code": "MALE",
      "weight": 0.5
    },
    "audience_geo": [
      {
        "id": 0,
        "weight": 0.05
      }
    ],
    "audience_lang": {
      "code": "st",
      "weight": 0.2
    },
    "audience_relevance": {
      "value": "string"
    },
    "engagements": {
      "left_number": 0,
      "right_number": 0
    },
    "views": {
      "left_number": 0,
      "right_number": 0
    },
    "posts_count": {
      "left_number": 0,
      "right_number": 0
    },
    "reels_plays": {
      "left_number": 0,
      "right_number": 0
    },
    "shares": {
      "left_number": 0,
      "right_number": 0
    },
    "saves": {
      "left_number": 0,
      "right_number": 0
    },
    "followers": {
      "left_number": 0,
      "right_number": 0
    },
    "gender": {
      "code": "MALE"
    },
    "age": {
      "left_number": "string",
      "right_number": "string"
    },
    "geo": [
      {
        "id": 0
      }
    ],
    "lang": {
      "code": "st"
    },
    "followers_growth": {
      "interval": "i1month",
      "value": 0,
      "operator": "lt"
    },
    "total_views_growth": {
      "interval": "i1month",
      "value": 0,
      "operator": "lt"
    },
    "total_likes_growth": {
      "interval": "i1month",
      "value": 0,
      "operator": "lt"
    },
    "relevance": {
      "value": "string",
      "weight": 0.5,
      "threshold": 0.55
    },
    "text": "string",
    "keywords": "string",
    "text_tags": [
      {
        "type": "hashtag",
        "value": "string",
        "action": "must"
      }
    ],
    "engagement_rate": {
      "value": 0,
      "operator": "lt"
    },
    "is_hidden": true,
    "is_verified": true,
    "account_type": [
      0
    ],
    "with_contact": [
      {
        "type": "bbm",
        "action": "must"
      }
    ],
    "audience_credibility": 0,
    "audience_credibility_class": [
      "string"
    ],
    "list": [
      {
        "id": 0,
        "action": "must"
      }
    ],
    "filter_ids": [
      "string"
    ],
    "is_official_artist": true,
    "last_posted": 30,
    "actions": [
      {
        "filter": "followers",
        "action": "must"
      }
    ],
    "post_type": "all"
  },
  "sort": {
    "field": "engagements",
    "id": 0,
    "direction": "desc"
  },
  "paging": {
    "limit": 100,
    "skip": 0
  }
}



## Response sample 200:
{
  "accounts": [
    {
      "account": {
        "audience_source": "string",
        "user_profile": {
          "account_type": 1,
          "avg_views": 0,
          "custom_name": "string",
          "handle": "string",
          "engagement_rate": 0,
          "engagements": 0,
          "followers": 0,
          "fullname": "string",
          "is_verified": true,
          "picture": "string",
          "url": "string",
          "user_id": "string",
          "username": "string"
        },
        "search_result_id": "string",
        "hidden_result": true
      },
      "match": {
        "audience_likers": {
          "data": {
            "audience_ages": [
              {
                "code": "13-17",
                "weight": 0
              }
            ],
            "audience_age_range": {
              "code": "string",
              "weight": 0
            },
            "audience_brand_affinity": [
              {
                "id": 0,
                "name": "string",
                "interest": [
                  {}
                ],
                "weight": 0,
                "affinity": 0
              }
            ],
            "audience_credibility": 0,
            "audience_ethnicities": [
              {
                "code": "white",
                "name": "White / Caucasian",
                "weight": 0
              }
            ],
            "audience_genders": [
              {
                "code": "MALE",
                "weight": 0
              }
            ],
            "audience_genders_per_age": [
              {
                "code": "13-17",
                "male": 0,
                "female": 0
              }
            ],
            "audience_geo": {
              "countries": [
                {
                  "id": 0,
                  "name": "string",
                  "code": "string",
                  "weight": 0
                }
              ],
              "states": [
                {
                  "id": 0,
                  "name": "string",
                  "weight": 0,
                  "country": {}
                }
              ],
              "cities": [
                {
                  "id": 0,
                  "name": "string",
                  "coords": {},
                  "weight": 0,
                  "country": {}
                }
              ],
              "subdivisions": [
                {
                  "id": 0,
                  "name": "string",
                  "code": "string",
                  "items": [
                    null
                  ]
                }
              ]
            },
            "audience_interests": [
              {
                "id": 0,
                "name": "string",
                "weight": 0
              }
            ],
            "audience_languages": [
              {
                "code": "af",
                "name": "string",
                "weight": 0
              }
            ],
            "credibility_class": "string",
            "relevance": 0
          }
        },
        "user_profile": {
          "ads_brands": [
            {
              "id": 0,
              "name": "string",
              "interest": [
                {
                  "id": 0,
                  "name": "string"
                }
              ]
            }
          ],
          "age_group": "string",
          "avg_reels_plays": 0,
          "avg_shares": 0,
          "avg_saves": 0,
          "brand_affinity": [
            {
              "id": 0,
              "name": "string",
              "interest": [
                {
                  "id": 0,
                  "name": "string"
                }
              ]
            }
          ],
          "distance": 0,
          "followers_growth": 0,
          "gender": "MALE",
          "geo": {
            "city": {
              "id": 0,
              "name": "string",
              "coords": {
                "lat": 0,
                "lon": 0
              }
            },
            "country": {
              "id": 0,
              "name": "string",
              "coords": {
                "lat": 0,
                "lon": 0
              },
              "code": "string"
            },
            "subdivision": {
              "id": 0,
              "name": "string",
              "code": "string",
              "items": [
                {
                  "id": 0,
                  "name": "string",
                  "weight": 0
                }
              ]
            },
            "state": {
              "id": 0,
              "name": "string",
              "coords": {
                "lat": 0,
                "lon": 0
              }
            }
          },
          "interests": [
            {
              "id": 0,
              "name": "string"
            }
          ],
          "language": {
            "code": "af",
            "name": "string"
          },
          "posts_count": 0,
          "relevance": 0,
          "total_likes_growth": 0,
          "total_views_growth": 0
        }
      }
    }
  ],
  "total": 0,
  "shown_accounts": [
    0
  ],
  "cost": 0
}

## Response 400:

{
  "error": "string",
  "error_message": "string",
  "success": false
}

# https://api.iqfluence.io/v2.0/api/search/unhide/

## Request
{
  "search_result_ids": [
    "string"
  ]
}

# Response 200
{
  "accounts": [
    {
      "account": {
        "audience_source": "string",
        "user_profile": {
          "account_type": 1,
          "avg_views": 0,
          "custom_name": "string",
          "handle": "string",
          "engagement_rate": 0,
          "engagements": 0,
          "followers": 0,
          "fullname": "string",
          "is_verified": true,
          "picture": "string",
          "url": "string",
          "user_id": "string",
          "username": "string"
        }
      },
      "match": {
        "audience_likers": {
          "data": {
            "audience_ages": [
              {
                "code": "13-17",
                "weight": 0
              }
            ],
            "audience_age_range": {
              "code": "string",
              "weight": 0
            },
            "audience_brand_affinity": [
              {
                "id": 0,
                "name": "string",
                "interest": [
                  {}
                ],
                "weight": 0,
                "affinity": 0
              }
            ],
            "audience_credibility": 0,
            "audience_ethnicities": [
              {
                "code": "white",
                "name": "White / Caucasian",
                "weight": 0
              }
            ],
            "audience_genders": [
              {
                "code": "MALE",
                "weight": 0
              }
            ],
            "audience_genders_per_age": [
              {
                "code": "13-17",
                "male": 0,
                "female": 0
              }
            ],
            "audience_geo": {
              "countries": [
                {
                  "id": 0,
                  "name": "string",
                  "code": "string",
                  "weight": 0
                }
              ],
              "states": [
                {
                  "id": 0,
                  "name": "string",
                  "weight": 0,
                  "country": {}
                }
              ],
              "cities": [
                {
                  "id": 0,
                  "name": "string",
                  "coords": {},
                  "weight": 0,
                  "country": {}
                }
              ],
              "subdivisions": [
                {
                  "id": 0,
                  "name": "string",
                  "code": "string",
                  "items": [
                    null
                  ]
                }
              ]
            },
            "audience_interests": [
              {
                "id": 0,
                "name": "string",
                "weight": 0
              }
            ],
            "audience_languages": [
              {
                "code": "af",
                "name": "string",
                "weight": 0
              }
            ],
            "credibility_class": "string",
            "relevance": 0
          }
        }
      },
      "search_result_id": "string"
    }
  ],
  "cost": 0,
  "credits": 0
}


# https://api.iqfluence.io/v2.0/api/reports/new/

## QUERY PARAMETERS

url	
string
Username, userId or link to user's profile page.
ignore_removed	
boolean
Default: false
If you receive account_removed error we probably have old audience data for that account. To get it set this parameter to true
ignore_outdated	
boolean
Default: false
If you receive retry_later error we probably have an outdated information for that account. To get the report anyway set this parameter to true
ignore_empty_audience	
boolean
Default: false
If you want to ignore empty audience set this argument.
dry_run	
boolean
Default: false
Set to "true" or "1" to check whether the report can be built or not
platform	
string
Default: "instagram"
Enum: "instagram" "tiktok" "youtube"

## Response 200

{
  "success": true,
  "version": "2",
  "report_info": {
    "report_id": "string",
    "created": "2019-08-24T14:15:22Z",
    "profile_updated": "2019-08-24T14:15:22Z",
    "profile_is_updating": true
  },
  "user_profile": {
    "type": "instagram",
    "user_id": "string",
    "sec_uid": "string",
    "username": "string",
    "custom_name": "string",
    "handle": "string",
    "url": "string",
    "picture": "string",
    "fullname": "string",
    "description": "string",
    "is_hidden": true,
    "is_verified": true,
    "is_business": true,
    "is_official_artist": true,
    "account_type": 1,
    "gender": "MALE",
    "age_group": "string",
    "language": {
      "code": "af",
      "name": "string"
    },
    "followers": 0,
    "posts_count": 0,
    "engagements": 0,
    "engagement_rate": 0,
    "avg_likes": 0,
    "avg_dislikes": 0,
    "avg_comments": 0,
    "avg_views": 0,
    "avg_reels_plays": 0,
    "avg_shares": 0,
    "avg_saves": 0,
    "total_likes": 0,
    "total_views": 0,
    "stat_history": [
      {
        "month": "string",
        "followers": 0,
        "following": 0,
        "avg_likes": 0,
        "avg_dislikes": 0,
        "avg_comments": 0,
        "avg_views": 0,
        "avg_shares": 0,
        "avg_saves": 0,
        "total_views": 0,
        "total_likes": 0
      }
    ],
    "paid_post_perfomance": 0,
    "geo": {
      "city": {
        "id": 0,
        "name": "string",
        "coords": {
          "lat": 0,
          "lon": 0
        }
      },
      "country": {
        "id": 0,
        "name": "string",
        "coords": {
          "lat": 0,
          "lon": 0
        },
        "code": "string"
      },
      "subdivision": {
        "id": 0,
        "name": "string",
        "code": "string",
        "items": [
          {
            "id": 0,
            "name": "string",
            "weight": 0
          }
        ]
      },
      "state": {
        "id": 0,
        "name": "string",
        "coords": {
          "lat": 0,
          "lon": 0
        }
      }
    },
    "contacts": [
      {
        "type": "bbm",
        "value": "string",
        "formatted_value": "string",
        "checked": true
      }
    ],
    "top_hashtags": [
      {
        "tag": "string",
        "weight": 0
      }
    ],
    "top_mentions": [
      {
        "tag": "string",
        "weight": 0
      }
    ],
    "brand_affinity": [
      {
        "id": 0,
        "name": "string",
        "interest": [
          {
            "id": 0,
            "name": "string"
          }
        ]
      }
    ],
    "interests": [
      {
        "id": 0,
        "name": "string"
      }
    ],
    "relevant_tags": [
      {
        "tag": "string",
        "distance": 0,
        "freq": 0,
        "tag_cnt": 0
      }
    ],
    "similar_users": [
      {
        "user_id": "string",
        "username": "string",
        "custom_name": "string",
        "picture": "string",
        "followers": 0,
        "fullname": "string",
        "url": "string",
        "geo": {
          "city": {
            "id": 0,
            "name": "string",
            "coords": {
              "lat": 0,
              "lon": 0
            }
          },
          "country": {
            "id": 0,
            "name": "string",
            "coords": {
              "lat": 0,
              "lon": 0
            },
            "code": "string"
          },
          "subdivision": {
            "id": 0,
            "name": "string",
            "code": "string",
            "items": [
              {
                "id": 0,
                "name": "string",
                "weight": 0
              }
            ]
          },
          "state": {
            "id": 0,
            "name": "string",
            "coords": {
              "lat": 0,
              "lon": 0
            }
          }
        },
        "is_verified": true,
        "engagements": 0,
        "avg_likes": 0,
        "avg_comments": 0,
        "avg_views": 0,
        "stats": [
          {
            "post_type": "all",
            "engagements": 0,
            "avg_likes": 0,
            "avg_views": 0
          }
        ],
        "score": 0
      }
    ],
    "top_posts": [
      {
        "user_id": "string",
        "username": "string",
        "user_picture": "string",
        "user_url": "string",
        "type": "string",
        "post_id": "string",
        "created": "2019-08-24T14:15:22Z",
        "text": "",
        "link": "string",
        "mentions": [
          "string"
        ],
        "hashtags": [
          "string"
        ],
        "stat": {
          "likes": 0,
          "comments": 0,
          "views": 0,
          "plays": 0,
          "shares": 0,
          "saves": 0
        },
        "sponsor": {
          "user_id": "string",
          "username": "string"
        },
        "image": "string",
        "video": "string",
        "thumbnail": "string"
      }
    ],
    "commercial_posts": [
      {
        "user_id": "string",
        "username": "string",
        "user_picture": "string",
        "user_url": "string",
        "type": "string",
        "post_id": "string",
        "created": "2019-08-24T14:15:22Z",
        "text": "",
        "link": "string",
        "mentions": [
          "string"
        ],
        "hashtags": [
          "string"
        ],
        "stat": {
          "likes": 0,
          "comments": 0,
          "views": 0,
          "plays": 0,
          "shares": 0,
          "saves": 0
        },
        "sponsor": {
          "user_id": "string",
          "username": "string"
        },
        "image": "string",
        "video": "string",
        "thumbnail": "string"
      }
    ],
    "recent_posts": [
      {
        "user_id": "string",
        "username": "string",
        "user_picture": "string",
        "user_url": "string",
        "type": "string",
        "post_id": "string",
        "created": "2019-08-24T14:15:22Z",
        "text": "",
        "link": "string",
        "mentions": [
          "string"
        ],
        "hashtags": [
          "string"
        ],
        "stat": {
          "likes": 0,
          "comments": 0,
          "views": 0,
          "plays": 0,
          "shares": 0,
          "saves": 0
        },
        "sponsor": {
          "user_id": "string",
          "username": "string"
        },
        "image": "string",
        "video": "string"
      }
    ],
    "top_reels": [
      {
        "user_id": "string",
        "username": "string",
        "user_picture": "string",
        "user_url": "string",
        "type": "string",
        "post_id": "string",
        "created": "2019-08-24T14:15:22Z",
        "text": "",
        "link": "string",
        "mentions": [
          "string"
        ],
        "hashtags": [
          "string"
        ],
        "stat": {
          "likes": 0,
          "comments": 0,
          "views": 0,
          "plays": 0,
          "shares": 0,
          "saves": 0
        },
        "sponsor": {
          "user_id": "string",
          "username": "string"
        },
        "image": "string",
        "video": "string",
        "thumbnail": "string"
      }
    ],
    "recent_reels": [
      {
        "user_id": "string",
        "username": "string",
        "user_picture": "string",
        "user_url": "string",
        "type": "string",
        "post_id": "string",
        "created": "2019-08-24T14:15:22Z",
        "text": "",
        "link": "string",
        "mentions": [
          "string"
        ],
        "hashtags": [
          "string"
        ],
        "stat": {
          "likes": 0,
          "comments": 0,
          "views": 0,
          "plays": 0,
          "shares": 0,
          "saves": 0
        },
        "sponsor": {
          "user_id": "string",
          "username": "string"
        },
        "image": "string",
        "video": "string"
      }
    ],
    "stats": [
      {
        "post_type": "all",
        "engagements": 0,
        "engagement_rate": 0,
        "avg_likes": 0,
        "avg_comments": 0,
        "avg_views": 0,
        "avg_reels_plays": 0,
        "avg_shares": 0,
        "avg_saves": 0,
        "avg_posts4w": 0,
        "stat_history": [
          {
            "month": "string",
            "avg_likes": 0,
            "avg_engagements": 0,
            "avg_views": 0,
            "avg_comments": 0,
            "avg_shares": 0,
            "avg_saves": 0
          }
        ]
      }
    ]
  },
  "audience_likers": {
    "success": true,
    "error": "empty_audience",
    "error_message": "string",
    "data": {
      "notable_users_ratio": 0,
      "audience_credibility": 0,
      "credibility_class": "bad",
      "audience_types": [
        {
          "code": "mass_followers",
          "weight": 0
        }
      ],
      "audience_genders": [
        {
          "code": "MALE",
          "weight": 0
        }
      ],
      "audience_ages": [
        {
          "code": "13-17",
          "weight": 0
        }
      ],
      "audience_genders_per_age": [
        {
          "code": "13-17",
          "male": 0,
          "female": 0
        }
      ],
      "audience_ethnicities": [
        {
          "code": "white",
          "name": "White / Caucasian",
          "weight": 0
        }
      ],
      "audience_languages": [
        {
          "code": "af",
          "name": "string",
          "weight": 0
        }
      ],
      "audience_brand_affinity": [
        {
          "id": 0,
          "name": "string",
          "interest": [
            {
              "id": 0,
              "name": "string"
            }
          ],
          "weight": 0,
          "affinity": 0
        }
      ],
      "audience_interests": [
        {
          "id": 0,
          "name": "string",
          "weight": 0
        }
      ],
      "audience_geo": {
        "countries": [
          {
            "id": 0,
            "name": "string",
            "code": "string",
            "weight": 0
          }
        ],
        "states": [
          {
            "id": 0,
            "name": "string",
            "weight": 0,
            "country": {
              "id": 0,
              "name": "string",
              "code": "string"
            }
          }
        ],
        "cities": [
          {
            "id": 0,
            "name": "string",
            "coords": {
              "lat": 0,
              "lon": 0
            },
            "weight": 0,
            "country": {
              "id": 0,
              "name": "string",
              "code": "string"
            }
          }
        ],
        "subdivisions": [
          {
            "id": 0,
            "name": "string",
            "code": "string",
            "items": [
              {
                "id": 0,
                "name": "string",
                "weight": 0
              }
            ]
          }
        ]
      },
      "audience_lookalikes": [
        {
          "user_id": "string",
          "username": "string",
          "custom_name": "string",
          "picture": "string",
          "followers": 0,
          "fullname": "string",
          "url": "string",
          "geo": {
            "city": {
              "id": 0,
              "name": "string",
              "coords": {
                "lat": 0,
                "lon": 0
              }
            },
            "country": {
              "id": 0,
              "name": "string",
              "coords": {
                "lat": 0,
                "lon": 0
              },
              "code": "string"
            },
            "subdivision": {
              "id": 0,
              "name": "string",
              "code": "string",
              "items": [
                {
                  "id": 0,
                  "name": "string",
                  "weight": 0
                }
              ]
            },
            "state": {
              "id": 0,
              "name": "string",
              "coords": {
                "lat": 0,
                "lon": 0
              }
            }
          },
          "is_verified": true,
          "engagements": 0,
          "avg_likes": 0,
          "avg_comments": 0,
          "avg_views": 0,
          "stats": [
            {
              "post_type": "all",
              "engagements": 0,
              "avg_likes": 0,
              "avg_views": 0
            }
          ],
          "score": 0
        }
      ],
      "notable_users": [
        {
          "user_id": "string",
          "username": "string",
          "custom_name": "string",
          "picture": "string",
          "followers": 0,
          "fullname": "string",
          "url": "string",
          "geo": {
            "city": {
              "id": 0,
              "name": "string",
              "coords": {
                "lat": 0,
                "lon": 0
              }
            },
            "country": {
              "id": 0,
              "name": "string",
              "coords": {
                "lat": 0,
                "lon": 0
              },
              "code": "string"
            },
            "subdivision": {
              "id": 0,
              "name": "string",
              "code": "string",
              "items": [
                {
                  "id": 0,
                  "name": "string",
                  "weight": 0
                }
              ]
            },
            "state": {
              "id": 0,
              "name": "string",
              "coords": {
                "lat": 0,
                "lon": 0
              }
            }
          },
          "is_verified": true,
          "engagements": 0,
          "avg_likes": 0,
          "avg_comments": 0,
          "avg_views": 0,
          "stats": [
            {
              "post_type": "all",
              "engagements": 0,
              "avg_likes": 0,
              "avg_views": 0
            }
          ]
        }
      ],
      "audience_accounts_created_at": [
        {
          "code": "string",
          "weight": 0
        }
      ],
      "audience_reachability": [
        {
          "code": "-500",
          "weight": 0
        }
      ],
      "likes_not_from_followers": 0
    }
  },
  "audience_followers": {
    "success": true,
    "error": "empty_audience",
    "error_message": "string",
    "data": {
      "notable_users_ratio": 0,
      "audience_credibility": 0,
      "credibility_class": "bad",
      "audience_types": [
        {
          "code": "mass_followers",
          "weight": 0
        }
      ],
      "audience_genders": [
        {
          "code": "MALE",
          "weight": 0
        }
      ],
      "audience_ages": [
        {
          "code": "13-17",
          "weight": 0
        }
      ],
      "audience_genders_per_age": [
        {
          "code": "13-17",
          "male": 0,
          "female": 0
        }
      ],
      "audience_ethnicities": [
        {
          "code": "white",
          "name": "White / Caucasian",
          "weight": 0
        }
      ],
      "audience_languages": [
        {
          "code": "af",
          "name": "string",
          "weight": 0
        }
      ],
      "audience_brand_affinity": [
        {
          "id": 0,
          "name": "string",
          "interest": [
            {
              "id": 0,
              "name": "string"
            }
          ],
          "weight": 0,
          "affinity": 0
        }
      ],
      "audience_interests": [
        {
          "id": 0,
          "name": "string",
          "weight": 0
        }
      ],
      "audience_geo": {
        "countries": [
          {
            "id": 0,
            "name": "string",
            "code": "string",
            "weight": 0
          }
        ],
        "states": [
          {
            "id": 0,
            "name": "string",
            "weight": 0,
            "country": {
              "id": 0,
              "name": "string",
              "code": "string"
            }
          }
        ],
        "cities": [
          {
            "id": 0,
            "name": "string",
            "coords": {
              "lat": 0,
              "lon": 0
            },
            "weight": 0,
            "country": {
              "id": 0,
              "name": "string",
              "code": "string"
            }
          }
        ],
        "subdivisions": [
          {
            "id": 0,
            "name": "string",
            "code": "string",
            "items": [
              {
                "id": 0,
                "name": "string",
                "weight": 0
              }
            ]
          }
        ]
      },
      "audience_lookalikes": [
        {
          "user_id": "string",
          "username": "string",
          "custom_name": "string",
          "picture": "string",
          "followers": 0,
          "fullname": "string",
          "url": "string",
          "geo": {
            "city": {
              "id": 0,
              "name": "string",
              "coords": {
                "lat": 0,
                "lon": 0
              }
            },
            "country": {
              "id": 0,
              "name": "string",
              "coords": {
                "lat": 0,
                "lon": 0
              },
              "code": "string"
            },
            "subdivision": {
              "id": 0,
              "name": "string",
              "code": "string",
              "items": [
                {
                  "id": 0,
                  "name": "string",
                  "weight": 0
                }
              ]
            },
            "state": {
              "id": 0,
              "name": "string",
              "coords": {
                "lat": 0,
                "lon": 0
              }
            }
          },
          "is_verified": true,
          "engagements": 0,
          "avg_likes": 0,
          "avg_comments": 0,
          "avg_views": 0,
          "stats": [
            {
              "post_type": "all",
              "engagements": 0,
              "avg_likes": 0,
              "avg_views": 0
            }
          ],
          "score": 0
        }
      ],
      "notable_users": [
        {
          "user_id": "string",
          "username": "string",
          "custom_name": "string",
          "picture": "string",
          "followers": 0,
          "fullname": "string",
          "url": "string",
          "geo": {
            "city": {
              "id": 0,
              "name": "string",
              "coords": {
                "lat": 0,
                "lon": 0
              }
            },
            "country": {
              "id": 0,
              "name": "string",
              "coords": {
                "lat": 0,
                "lon": 0
              },
              "code": "string"
            },
            "subdivision": {
              "id": 0,
              "name": "string",
              "code": "string",
              "items": [
                {
                  "id": 0,
                  "name": "string",
                  "weight": 0
                }
              ]
            },
            "state": {
              "id": 0,
              "name": "string",
              "coords": {
                "lat": 0,
                "lon": 0
              }
            }
          },
          "is_verified": true,
          "engagements": 0,
          "avg_likes": 0,
          "avg_comments": 0,
          "avg_views": 0,
          "stats": [
            {
              "post_type": "all",
              "engagements": 0,
              "avg_likes": 0,
              "avg_views": 0
            }
          ]
        }
      ],
      "audience_accounts_created_at": [
        {
          "code": "string",
          "weight": 0
        }
      ],
      "audience_reachability": [
        {
          "code": "-500",
          "weight": 0
        }
      ]
    },
    "is_hidden": true
  },
  "audience_commenters": {
    "success": true,
    "error": "empty_audience",
    "error_message": "string",
    "data": {
      "notable_users_ratio": 0,
      "audience_credibility": 0,
      "credibility_class": "bad",
      "audience_types": [
        {
          "code": "mass_followers",
          "weight": 0
        }
      ],
      "audience_genders": [
        {
          "code": "MALE",
          "weight": 0
        }
      ],
      "audience_ages": [
        {
          "code": "13-17",
          "weight": 0
        }
      ],
      "audience_genders_per_age": [
        {
          "code": "13-17",
          "male": 0,
          "female": 0
        }
      ],
      "audience_ethnicities": [
        {
          "code": "white",
          "name": "White / Caucasian",
          "weight": 0
        }
      ],
      "audience_languages": [
        {
          "code": "af",
          "name": "string",
          "weight": 0
        }
      ],
      "audience_brand_affinity": [
        {
          "id": 0,
          "name": "string",
          "interest": [
            {
              "id": 0,
              "name": "string"
            }
          ],
          "weight": 0,
          "affinity": 0
        }
      ],
      "audience_interests": [
        {
          "id": 0,
          "name": "string",
          "weight": 0
        }
      ],
      "audience_geo": {
        "countries": [
          {
            "id": 0,
            "name": "string",
            "code": "string",
            "weight": 0
          }
        ],
        "states": [
          {
            "id": 0,
            "name": "string",
            "weight": 0,
            "country": {
              "id": 0,
              "name": "string",
              "code": "string"
            }
          }
        ],
        "cities": [
          {
            "id": 0,
            "name": "string",
            "coords": {
              "lat": 0,
              "lon": 0
            },
            "weight": 0,
            "country": {
              "id": 0,
              "name": "string",
              "code": "string"
            }
          }
        ],
        "subdivisions": [
          {
            "id": 0,
            "name": "string",
            "code": "string",
            "items": [
              {
                "id": 0,
                "name": "string",
                "weight": 0
              }
            ]
          }
        ]
      },
      "audience_lookalikes": [
        {
          "user_id": "string",
          "username": "string",
          "custom_name": "string",
          "picture": "string",
          "followers": 0,
          "fullname": "string",
          "url": "string",
          "geo": {
            "city": {
              "id": 0,
              "name": "string",
              "coords": {
                "lat": 0,
                "lon": 0
              }
            },
            "country": {
              "id": 0,
              "name": "string",
              "coords": {
                "lat": 0,
                "lon": 0
              },
              "code": "string"
            },
            "subdivision": {
              "id": 0,
              "name": "string",
              "code": "string",
              "items": [
                {
                  "id": 0,
                  "name": "string",
                  "weight": 0
                }
              ]
            },
            "state": {
              "id": 0,
              "name": "string",
              "coords": {
                "lat": 0,
                "lon": 0
              }
            }
          },
          "is_verified": true,
          "engagements": 0,
          "avg_likes": 0,
          "avg_comments": 0,
          "avg_views": 0,
          "stats": [
            {
              "post_type": "all",
              "engagements": 0,
              "avg_likes": 0,
              "avg_views": 0
            }
          ],
          "score": 0
        }
      ],
      "notable_users": [
        {
          "user_id": "string",
          "username": "string",
          "custom_name": "string",
          "picture": "string",
          "followers": 0,
          "fullname": "string",
          "url": "string",
          "geo": {
            "city": {
              "id": 0,
              "name": "string",
              "coords": {
                "lat": 0,
                "lon": 0
              }
            },
            "country": {
              "id": 0,
              "name": "string",
              "coords": {
                "lat": 0,
                "lon": 0
              },
              "code": "string"
            },
            "subdivision": {
              "id": 0,
              "name": "string",
              "code": "string",
              "items": [
                {
                  "id": 0,
                  "name": "string",
                  "weight": 0
                }
              ]
            },
            "state": {
              "id": 0,
              "name": "string",
              "coords": {
                "lat": 0,
                "lon": 0
              }
            }
          },
          "is_verified": true,
          "engagements": 0,
          "avg_likes": 0,
          "avg_comments": 0,
          "avg_views": 0,
          "stats": [
            {
              "post_type": "all",
              "engagements": 0,
              "avg_likes": 0,
              "avg_views": 0
            }
          ]
        }
      ],
      "audience_accounts_created_at": [
        {
          "code": "string",
          "weight": 0
        }
      ],
      "audience_reachability": [
        {
          "code": "-500",
          "weight": 0
        }
      ]
    }
  },
  "extra": {
    "followers_range": {
      "left_number": 0,
      "right_number": 0
    },
    "engagement_rate_histogram": [
      {
        "min": 0,
        "max": 0,
        "total": 0,
        "median": true
      }
    ],
    "audience_credibility_followers_histogram": [
      {
        "min": 0,
        "max": 0,
        "total": 0,
        "median": true
      }
    ],
    "audience_credibility_likers_histogram": [
      {
        "min": 0,
        "max": 0,
        "total": 0,
        "median": true
      }
    ]
  }
}

report.json
report-2.json
report-3.json


# Directories

## Topics


q
required
string
Default: ""
Search query. Use # symbol for hashtags and @ for usernames, don't forget to encode them properly as a part of URI.

Examples: q=%23prank to search for #prank, q=%40instagram to search for @instagram.

For YouTube you can use channel ID instead of username, i.e. @UCBR8-60-B28hp2BmDPdntcQ for the official YouTube's channel.
limit	
integer [ 1 .. 100 ]
Default: 60
Limits the maximum number of results
platform	
string
Default: "instagram"
Enum: "instagram" "tiktok" "youtube"

### Response
{
  "success": true,
  "data": [
    {
      "tag": "#prank",
      "distance": 5.960464477539063e-8,
      "freq": 11.34840453280178,
      "tag_cnt": 84830
    },
    {
      "tag": "#pranks",
      "distance": 0.0885847806930542,
      "freq": 9.283590833715776,
      "tag_cnt": 10760
    }
  ]
}

## https://api.iqfluence.io/v2.0/api/geos/

## Response 200

[
  {
    "id": 51800,
    "type": [
      "city"
    ],
    "name": "London",
    "title": "London, United Kingdom",
    "country": {
      "id": 62149
    }
  },
  {
    "id": 297756,
    "type": [
      "city"
    ],
    "name": "Londrina",
    "title": "Londrina, Brazil",
    "country": {
      "id": 59470
    }
  }
]