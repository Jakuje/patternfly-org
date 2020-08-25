import React from 'react';
import { Link } from '../link/link';
import { Nav, NavList, NavExpandable, capitalize } from '@patternfly/react-core';
import { css } from '@patternfly/react-styles';
import { slugger } from '../../helpers';
import './sideNav.css';

const NavItem = ({ text, href }) => (
  <li key={href + text} className="pf-c-nav__item">
    <Link
      to={href}
      getProps={({ isCurrent, href, location }) => {
        const { pathname } = location;
        return {
          className: css(
            'pf-c-nav__link',
            (isCurrent || pathname.startsWith(href + '/')) && 'pf-m-current'
          )
        }}
      }
    >
      {text}
    </Link>
  </li>
);

export const SideNav = ({
  location = typeof window !== 'undefined' ? window.location : { pathname: '/' },
  groupedRoutes = {},
  navItems = []
}) => {
  React.useEffect(() => {
    if (typeof window === 'undefined') {
      return;
    }
    const overflowElement = document.getElementById('page-sidebar');
    if (!overflowElement) {
      return;
    }
    const activeElements = overflowElement.getElementsByClassName('pf-m-current');
    if (activeElements.length > 0) {
      const lastElement = activeElements[activeElements.length - 1];
      lastElement.scrollIntoView({ block: 'center' });
    }
  }, []);
  
  return (
    <Nav aria-label="Side Nav" theme="light">
      <NavList className="ws-side-nav-list">
        {navItems.map(({ section, text, href }) => {
          if (!section) {
            // Single nav item
            return NavItem({
              text: text || capitalize(href.replace(/\//g, '').replace(/-/g, ' ')),
              href: href
            });
          }
          else {
            const isActive = location.pathname.includes(`/${slugger(section)}/`);
            return (
              <NavExpandable
                key={section}
                title={capitalize(section.replace(/-/g, ' '))}
                isActive={isActive}
                isExpanded={isActive}
                className="ws-side-nav-group"
              >
                {Object.entries(groupedRoutes[section] || {})
                  .map(([id, { slug }]) => ({ text: id, href: slug }))
                  .sort(({ text: text1 }, { text: text2 }) => text1.localeCompare(text2))
                  .map(NavItem)
                }
              </NavExpandable>
            );
          }
        })}
      </NavList>
    </Nav>
  );
}
